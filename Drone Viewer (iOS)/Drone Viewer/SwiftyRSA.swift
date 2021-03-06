//
//  SwiftyRSA.swift
//  SwiftyRSA
//
//  Created by Loïs Di Qual on 7/2/15.
//  Copyright (c) 2015 Scoop Technologies, Inc. All rights reserved.
//

import Foundation
import Security

public class SwiftyRSAError: NSError {
    init(message: String) {
        super.init(domain: "com.takescoop.SwiftyRSA", code: 500, userInfo: [
            NSLocalizedDescriptionKey: message
        ])
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class SwiftyRSA {
    
    private var keyTags: [NSData] = []
    private static let defaultPadding: SecPadding = .PKCS1
    
    // MARK: - Public Advanced Methods
    
    public init() {}
    
    public func publicKeyFromDERData(keyData: NSData) throws -> SecKeyRef {
        return try addKey(keyData, isPublic: true)
    }
    
    public func publicKeyFromPEMString(key: String) throws -> SecKeyRef {
        let data = try dataFromPEMKey(key)
        return try addKey(data, isPublic: true)
    }
    
    public func privateKeyFromPEMString(key: String) throws -> SecKeyRef {
        let data = try dataFromPEMKey(key)
        return try addKey(data, isPublic: false)
    }
    
    // MARK: - Private
    
    private func addKey(keyData: NSData, isPublic: Bool) throws -> SecKeyRef {
        
        var keyData = keyData
        
        // Strip key header if necessary
        if isPublic {
            try keyData = stripPublicKeyHeader(keyData)
        }
        
        let tag = NSUUID().UUIDString
        let tagData = NSData(bytes: tag, length: tag.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        removeKeyWithTagData(tagData)
        
        // Add persistent version of the key to system keychain
        let persistKey = UnsafeMutablePointer<AnyObject?>(nil)
        let keyClass   = isPublic ? kSecAttrKeyClassPublic : kSecAttrKeyClassPrivate
        
        // Add persistent version of the key to system keychain
        let keyDict = NSMutableDictionary()
        keyDict.setObject(kSecClassKey,         forKey: kSecClass as! NSCopying)
        keyDict.setObject(tagData,              forKey: kSecAttrApplicationTag as! NSCopying)
        keyDict.setObject(kSecAttrKeyTypeRSA,   forKey: kSecAttrKeyType as! NSCopying)
        keyDict.setObject(keyData,              forKey: kSecValueData as! NSCopying)
        keyDict.setObject(keyClass,             forKey: kSecAttrKeyClass as! NSCopying)
        keyDict.setObject(NSNumber(bool: true), forKey: kSecReturnPersistentRef as! NSCopying)
        keyDict.setObject(kSecAttrAccessibleWhenUnlocked, forKey: kSecAttrAccessible as! NSCopying)
        
        var secStatus = SecItemAdd(keyDict as CFDictionary, persistKey)
        if secStatus != noErr && secStatus != errSecDuplicateItem {
            throw SwiftyRSAError(message: "Provided key couldn't be added to the keychain")
        }
        
        keyTags.append(tagData)
        
        // Now fetch the SecKeyRef version of the key
        var keyRef: AnyObject? = nil
        keyDict.removeObjectForKey(kSecValueData)
        keyDict.removeObjectForKey(kSecReturnPersistentRef)
        keyDict.setObject(NSNumber(bool: true), forKey: kSecReturnRef as! NSCopying)
        keyDict.setObject(kSecAttrKeyTypeRSA,   forKey: kSecAttrKeyType as! NSCopying)
        secStatus = SecItemCopyMatching(keyDict as CFDictionaryRef, &keyRef)
        
        guard let unwrappedKeyRef = keyRef else {
            throw SwiftyRSAError(message: "Couldn't get key reference from the keychain")
        }
        
        return unwrappedKeyRef as! SecKeyRef
    }
    
    private func dataFromPEMKey(key: String) throws -> NSData {
        let rawLines = key.componentsSeparatedByString("\n")
        var lines = [String]()
        
        for line in rawLines {
            if line == "-----BEGIN RSA PRIVATE KEY-----" ||
                line == "-----END RSA PRIVATE KEY-----"   ||
                line == "-----BEGIN PUBLIC KEY-----" ||
                line == "-----END PUBLIC KEY-----"   ||
                line == "" {
                    continue
            }
            lines.append(line)
        }
        
        if lines.count == 0 {
            throw SwiftyRSAError(message: "Couldn't get data from PEM key: no data available after stripping headers")
        }
        
        // Decode base64 key
        let base64EncodedKey = lines.joinWithSeparator("")
        let keyData = NSData(base64EncodedString: base64EncodedKey, options: .IgnoreUnknownCharacters)
        
        guard let unwrappedKeyData = keyData where unwrappedKeyData.length != 0 else {
            throw SwiftyRSAError(message: "Couldn't decode PEM key data (base64)")
        }
        
        return unwrappedKeyData
    }
    
    private func stripPublicKeyHeader(keyData: NSData) throws -> NSData {
        let count = keyData.length / sizeof(CUnsignedChar)
        var byteArray = [CUnsignedChar](count: count, repeatedValue: 0)
        keyData.getBytes(&byteArray, length: keyData.length)
        
        var index = 0
        if byteArray[index] != 0x30 {
            throw SwiftyRSAError(message: "Invalid byte at index 0 (\(byteArray[0])) for public key header")
        }
        index += 1
        
        if byteArray[index] > 0x80 {
            index += Int(byteArray[index]) - 0x80 + 1
        }
        else {
            index += 1
        }
        
        let seqiod: [CUnsignedChar] = [0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
            0x01, 0x05, 0x00]
        byteArray.replaceRange(Range<Int>(index ..< index + seqiod.count), with: seqiod)
        
        index += 15
        
        if byteArray[index] != 0x03 {
            throw SwiftyRSAError(message: "Invalid byte at index \(index - 1) (\(byteArray[index - 1])) for public key header")
        }
        index += 1
        
        if byteArray[index] > 0x80 {
            index += Int(byteArray[index]) - 0x80 + 1
        }
        else {
            index += 1
        }
        
        if byteArray[index] != 0 {
            throw SwiftyRSAError(message: "Invalid byte at index \(index - 1) (\(byteArray[index - 1])) for public key header")
        }
        index += 1
        
        let test = [CUnsignedChar](byteArray[index...keyData.length - 1])
        
        let data = NSData(bytes: test, length: keyData.length - index)
        
        return data
    }
    
    private func removeKeyWithTagData(tagData: NSData) {
        let publicKey = NSMutableDictionary()
        publicKey.setObject(kSecClassKey,       forKey: kSecClass as! NSCopying)
        publicKey.setObject(kSecAttrKeyTypeRSA, forKey: kSecAttrKeyType as! NSCopying)
        publicKey.setObject(tagData,            forKey: kSecAttrApplicationTag as! NSCopying)
        SecItemDelete(publicKey as CFDictionaryRef)
    }
    
    deinit {
        for tagData in keyTags {
            removeKeyWithTagData(tagData)
        }
    }
}
