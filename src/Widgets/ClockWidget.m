/**
 * @file ClockWidget.m
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

#import "ClockWidget.h"
#import "FixedSizeLabel.h"
#import "WeatherWidget.h"

@interface ClockInternalWidget : CustomWidget
@property (retain) NSDateFormatter *formatter;
@property (retain) NSTimer *timer;
@end

@implementation ClockInternalWidget
- (void)commonInit
{
    self.customizationLabel = @"Clock";

    FixedSizeLabel *label = [FixedSizeLabel labelWithString:@"9:41 am"];
    label.wantsLayer = YES;
    label.layer.cornerRadius = 8.0;
    label.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];
    label.fixedSize = NSMakeSize(80, NSViewNoIntrinsicMetric);
    label.alignment = NSTextAlignmentCenter;
    self.view = label;

    self.formatter = [[[NSDateFormatter alloc] init] autorelease];
    self.formatter.dateFormat = @"h:mm a";
}

- (void)dealloc
{
    self.formatter = nil;
    self.timer = nil;

    [super dealloc];
}

- (void)viewWillAppear
{
    [self start];
}

- (void)viewDidDisappear
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

- (void)resetClock
{
    if (nil == self.timer)
        return;

    [self tick:nil];
}
@end

@implementation ClockWidget
{
    NSUInteger _temperatureUnit;
    BOOL _showsWeather;
    id _target;
    SEL _action;
}

- (void)commonInit
{
    [self addWidget:[[[ClockInternalWidget alloc]
        initWithIdentifier:@"_ClockInternal"] autorelease]];
}

- (void)resetClock
{
    ClockInternalWidget *widget = (id)[self.widgets objectAtIndex:0];
    [widget resetClock];
}

- (void)resetWeather
{
    WeatherWidget *widget = 2 <= self.widgets.count ? (id)[self.widgets objectAtIndex:1] : nil;
    [widget resetWeather];
}

- (NSDateFormatter *)formatter
{
    ClockInternalWidget *widget = (id)[self.widgets objectAtIndex:0];
    return widget.formatter;
}

- (void)setFormatter:(NSDateFormatter *)value
{
    ClockInternalWidget *widget = (id)[self.widgets objectAtIndex:0];
    widget.formatter = value;
}

- (NSUInteger)temperatureUnit
{
    return _temperatureUnit;
}

- (void)setTemperatureUnit:(NSUInteger)value
{
    _temperatureUnit = value;

    WeatherWidget *widget = 2 <= self.widgets.count ? (id)[self.widgets objectAtIndex:1] : nil;
    widget.temperatureUnit = value;
}

- (BOOL)showsWeather
{
    return _showsWeather;
}

- (void)setShowsWeather:(BOOL)value
{
    if (_showsWeather == value)
        return;

    _showsWeather = value;
    if (_showsWeather)
    {
        WeatherWidget *widget = [[[WeatherWidget alloc]
            initWithIdentifier:@"_Weather"] autorelease];
        widget.temperatureUnit = _temperatureUnit;
        [self addWidget:widget];
    }
    else
        [self removeWidgetWithIdentifier:@"_Weather"];
}

- (void)setPressTarget:(id)target action:(SEL)action
{
    _target = target;
    _action = action;
}

- (void)longPressAction:(id)sender
{
    [_target performSelector:_action withObject:self];
}
@end
