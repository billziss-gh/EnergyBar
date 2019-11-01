/**
 * @file AudioControl.h
 *
 * @copyright 2018-2019 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import <Cocoa/Cocoa.h>

@interface AudioControl : NSObject
+ (AudioControl *)sharedInstance;
@property (getter=volume, setter=setVolume:) double volume;
@property (getter=isMute, setter=setMute:) BOOL mute;
@end

extern NSString *AudioControlNotification;
