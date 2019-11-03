/**
 * @file NowPlayingWidget.h
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
#import "CustomWidget.h"

@interface NowPlayingWidget : CustomMultiWidget
@property (getter=showsActiveAppOnTap, setter=setShowsActiveAppOnTap:) BOOL showsActiveAppOnTap;
@property (getter=showsTodoOnTap, setter=setShowsTodoOnTap:) BOOL showsTodoOnTap;
@property (getter=showsSmallWidget, setter=setShowsSmallWidget:) BOOL showsSmallWidget;
@property (getter=todoShowsEventsInterval, setter=todoSetShowsEventsInterval:)
    double todoShowsEventsInterval;
@property (getter=todoShowsReminders, setter=todoSetShowsReminders:) BOOL todoShowsReminders;
- (void)todoReset;
@end
