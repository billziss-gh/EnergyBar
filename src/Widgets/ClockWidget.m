/**
 * @file ClockWidget.m
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

#import "ClockWidget.h"

@interface ClockWidgetLabel : NSTextField
@end

@implementation ClockWidgetLabel
- (NSSize)intrinsicContentSize
{
    NSSize size = [super intrinsicContentSize];
    size.width = MAX(size.width, 80);
    return size;
}
@end

@interface ClockWidget ()
@property (retain) NSTimer *timer;
@end

@implementation ClockWidget
{
    id _target;
    SEL _action;
}

- (void)commonInit
{
    self.customizationLabel = @"Clock";
    NSPressGestureRecognizer *recognizer = [[[NSPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(pressAction:)] autorelease];
    recognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    recognizer.minimumPressDuration = 1.0;
    ClockWidgetLabel *label = [ClockWidgetLabel labelWithString:@"9:41 am"];
    label.alignment = NSTextAlignmentCenter;
    [label addGestureRecognizer:recognizer];
    self.view = label;

    self.formatter = [[[NSDateFormatter alloc] init] autorelease];
    self.formatter.dateFormat = @"h:mm a";
}

- (void)dealloc
{
    self.timer = nil;
    self.formatter = nil;
    [super dealloc];
}

- (void)viewWillAppear
{
    [self start];
}

- (void)viewWillDisappear
{
    [self stop];
}

- (void)start
{
    if (nil != self.timer)
        return;

    NSDate *date = [[NSDate date] dateByAddingTimeInterval:60.0];
    NSDateComponents *comp = [[NSCalendar currentCalendar]
        components:NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|
            NSCalendarUnitHour|NSCalendarUnitMinute
        fromDate:date];
    date = [[NSCalendar currentCalendar] dateFromComponents:comp];

    self.timer = [[[NSTimer alloc]
        initWithFireDate:date
        interval:60.0
        target:self
        selector:@selector(tick:)
        userInfo:nil
        repeats:YES] autorelease];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];

    [self tick:nil];
}

- (void)stop
{
    if (nil == self.timer)
        return;

    [self.timer invalidate];
    self.timer = nil;
}

- (void)tick:(NSTimer *)sender
{
    NSTextField *view = self.view;
    view.stringValue = [self.formatter stringFromDate:[NSDate date]];
}

- (void)setPressTarget:(id)target action:(SEL)action
{
    _target = target;
    _action = action;
}

- (void)pressAction:(NSGestureRecognizer *)recognizer
{
    if (NSGestureRecognizerStateBegan != recognizer.state)
        return;

    [_target performSelector:_action withObject:self];
}
@end
