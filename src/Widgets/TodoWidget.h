/**
 * @file TodoWidget.h
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

@interface TodoWidget : CustomWidget
@property (atomic, assign) double showsEventsInterval;
@property (atomic, assign) BOOL showsReminders;
- (void)reset;
@end
