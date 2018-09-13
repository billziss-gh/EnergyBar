/**
 * @file PowerStatus.m
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

#import "PowerStatus.h"
#import <IOKit/ps/IOPowerSources.h>

static void PowerStatusCallback(void *context)
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:PowerStatusNotification
        object:context];
}

@implementation PowerStatus
{
    CFRunLoopSourceRef _source;
}

+ (PowerStatus *)sharedInstance
{
    static PowerStatus *instance = 0;
    if (0 == instance)
        instance = [[PowerStatus alloc] init];
    return instance;
}

- (id)init
{
    CFRunLoopSourceRef source = IOPSNotificationCreateRunLoopSource(PowerStatusCallback, self);
    if (0 == source)
        return nil;

    self = [super init];
    if (nil == self)
        return nil;

    _source = source;
    CFRunLoopAddSource(CFRunLoopGetCurrent(), _source, kCFRunLoopDefaultMode);

    return self;
}

- (void)dealloc
{
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _source, kCFRunLoopDefaultMode);

    [super dealloc];
}

- (NSTimeInterval)remainingTime
{
    NSTimeInterval time = IOPSGetTimeRemainingEstimate();
    if (kIOPSTimeRemainingUnknown == time)
        time = NAN;
    else if (kIOPSTimeRemainingUnlimited == time)
        time = +INFINITY;
    return time;
}

- (NSDictionary *)providingSourceInfoDictionary
{
    NSDictionary *info = nil;

    CFTypeRef blob = IOPSCopyPowerSourcesInfo();
    if (0 != blob)
    {
        CFArrayRef list = IOPSCopyPowerSourcesList(blob);
        if (0 != list)
        {
            if (0 < CFArrayGetCount(list))
                info = [[(id)IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(list, 0))
                    retain] autorelease];

            CFRelease(list);
        }

        CFRelease(blob);
    }

    return info;
}
@end

NSString *PowerStatusSourceState = @kIOPSPowerSourceStateKey;
NSString *PowerStatusCurrentCapacity = @kIOPSCurrentCapacityKey;
NSString *PowerStatusMaxCapacity = @kIOPSMaxCapacityKey;
NSString *PowerStatusIsCharging = @kIOPSIsChargingKey;
NSString *PowerStatusIsCharged = @kIOPSIsChargedKey;

NSString *PowerStatusNotification = @"PowerStatus";
