package de.lhtechnologies.flightComputer;

import gnu.io.*;

import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.Observable;

import static de.lhtechnologies.CommunicationProtocol.*;

/**
 * Created by ludger on 18.01.16.
 */
public class SerialReceiver extends Observable implements SerialPortEventListener {
    private static byte[] startMarker = "start".getBytes();

    public static int baudRate = 115200;
    public static int dataBits = SerialPort.DATABITS_8;
    public static int stopBits = SerialPort.STOPBITS_1;
    public static int parity = SerialPort.PARITY_NONE;

    private InputStream in;

    private byte[] inputBuffer = new byte[256];
    private int payloadLength = 0;

    public SerialReceiver(InputStream in) {
        this.in = in;
    }

    @Override
    public void serialEvent(SerialPortEvent theEvent) {
        assert(theEvent.getEventType() == SerialPortEvent.DATA_AVAILABLE);
        int inByte, checksum;
        int index = 0;
        try {
            while ((inByte = in.read()) > -1) {
                //First, synchronize on the start marker
                if (index < 5) {
                    if (inByte == startMarker[index]) {
                        index++;
                    } else {
                        index = 0;
                    }
                } else if (index == 5) {
                    //If we reached this part, we have received a valid start marker.
                    //The next byte is the length, add 5 + 1 + 1 to it to get the index of the final byte
                    payloadLength = inByte;
                    index++;
                } else if (index >= startMarker.length && index < (payloadLength + startMarker.length + 1)) {
                    //Now we are receiving the payload
                    inputBuffer[index - (startMarker.length + 1)] = (byte) inByte;
                    index++;
                } else {
                    //Reception complete. Verify checksum, create Protobuf object and notify the observers
                    int receivedChecksum = inByte;
                    int calculatedChecksum = calculateChecksum();
                    if (receivedChecksum == calculatedChecksum) {
                        byte[] rawMessage = Arrays.copyOfRange(inputBuffer, 0, payloadLength);
                        DroneMessage msg = DroneMessage.parseFrom(rawMessage);
                        setChanged();
                        notifyObservers(msg);
                    }
                    break;
                }
            }
        } catch (IOException e) {
            System.out.println("Error encountered. Exiting…");
            e.printStackTrace();
            System.exit(-1);
        }
    }
    public int calculateChecksum() {
        long checksum = 0;
        for(int i = 0; i < payloadLength; i++) {
            checksum += inputBuffer[i] & 0xFF; //To see the unsigned value
        }
        return (int) (checksum & 0xFF);
    }
}
