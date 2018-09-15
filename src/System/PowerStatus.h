/**
 * @file PowerStatus.h
 *
 * @copyright 2018 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import <Cocoa/Cocoa.h>

@interface PowerStatus : NSObject
+ (PowerStatus *)sharedInstance;
- (NSTimeInterval)remainingTime;
- (NSString *)providingSource;
- (NSDictionary *)providingSourceInfoDictionary;
@end

extern NSString *PowerStatusACPower;
extern NSString *PowerStatusBatteryPower;
extern NSString *PowerStatusUPSPower;
extern NSString *PowerStatusSourceState;
extern NSString *PowerStatusCurrentCapacity;
extern NSString *PowerStatusMaxCapacity;
extern NSString *PowerStatusIsCharging;
extern NSString *PowerStatusIsCharged;

extern NSString *PowerStatusNotification;
