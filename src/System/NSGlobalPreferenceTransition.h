/**
 * @file NSGlobalPreferenceTransition.h
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

typedef void (^NSGlobalPreferenceTransitionBlock)(void);

@interface NSGlobalPreferenceTransition : NSObject
+ (id)transition;
- (void)waitForTransitionWithCompletionHandler:(NSGlobalPreferenceTransitionBlock)arg1;
- (void)postChangeNotification:(unsigned long long)arg1
    completionHandler:(NSGlobalPreferenceTransitionBlock)arg2;
@end
