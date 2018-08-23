/**
 * @file CBBlueLightClient.h
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

typedef void (^CBBlueLightNotificationBlock)(void);

typedef struct
{
    float minCCT;
    float maxCCT;
    float midCCT;
} CBBlueLightTemperature;

typedef struct
{
    int hour;
    int minute;
} CBBlueLightTime;

typedef struct
{
    CBBlueLightTime fromTime;
    CBBlueLightTime toTime;
} CBBlueLightSchedule;

typedef struct
{
    char active;
    char enabled;
    char sunSchedulePermitted;
    int mode;
    CBBlueLightSchedule schedule;
    unsigned long long disableFlags;
} CBBlueLightStatus;

@interface CBBlueLightClient : NSObject
+ (BOOL)supportsBlueLightReduction;

- (id)init;
- (id)initWithClientObj:(id)arg1;

- (BOOL)getBlueLightStatus:(CBBlueLightStatus *)arg1;
- (BOOL)parseStatusDictionary:(id)arg1 intoStruct:(CBBlueLightStatus *)arg2;

- (BOOL)setSchedule:(const CBBlueLightSchedule *)arg1;
- (BOOL)setMode:(int)arg1;
- (BOOL)setEnabled:(BOOL)arg1;
- (BOOL)setEnabled:(BOOL)arg1 withOption:(int)arg2;
- (BOOL)setActive:(BOOL)arg1;

- (BOOL)getWarningStrength:(float *)arg1;
- (BOOL)getWarningCCT:(float *)arg1;
- (BOOL)getStrength:(float *)arg1;
- (BOOL)setStrength:(float)arg1 withPeriod:(float)arg2 commit:(BOOL)arg3;
- (BOOL)setStrength:(float)arg1 commit:(BOOL)arg2;

- (BOOL)getCCTRange:(CBBlueLightTemperature *)arg1;
- (BOOL)setCCTRange:(CBBlueLightTemperature *)arg1;
- (BOOL)getDefaultCCTRange:(CBBlueLightTemperature *)arg1;

- (BOOL)getCCT:(float *)arg1;
- (BOOL)setCCT:(float)arg1 commit:(BOOL)arg2;
- (BOOL)setCCT:(float)arg1 withPeriod:(float)arg2 commit:(BOOL)arg3;

- (void)setStatusNotificationBlock:(CBBlueLightNotificationBlock)arg1;
- (void)enableNotifications;
- (void)disableNotifications;
- (void)suspendNotifications:(BOOL)arg1;
- (void)suspendNotifications:(BOOL)arg1 force:(BOOL)arg2;

@property BOOL supported;
@end
