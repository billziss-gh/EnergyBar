/**
 * @file ClockWidget.h
 *
 * @copyright 2018 Bill Zissimopoulos
 */
/*
 * This file is part of TouchBarDock.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import <Cocoa/Cocoa.h>
#import "CustomWidget.h"

@interface ClockWidget : CustomWidget
- (void)start;
- (void)stop;
- (void)setPressTarget:(id)target action:(SEL)action;
@property (retain) IBOutlet NSDateFormatter *formatter;
@end
