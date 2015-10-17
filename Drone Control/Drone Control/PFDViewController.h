//
//  PFDViewController.h
//  Drone Control
//
//  Created by Ludger Heide on 13.10.15.
//  Copyright © 2015 Ludger Heide. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PFDViewController : NSViewController

@property (nonatomic) NSNumber* speed;
@property (nonatomic) NSNumber* altitude;
@property (nonatomic) NSNumber* pitch;
@property (nonatomic) NSNumber* roll;
@property (nonatomic) NSNumber* heading;

@end
