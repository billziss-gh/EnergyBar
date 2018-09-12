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
#import "ImageTitleView.h"
#import "PowerStatus.h"
#import "WeatherWidget.h"

@interface ClockWidgetView : ImageTitleView
@end

@implementation ClockWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(80, NSViewNoIntrinsicMetric);
}
@end

@interface ClockInternalWidget : CustomWidget
@property (retain) NSDateFormatter *formatter;
@property (retain) NSTimer *timer;
@property (assign) BOOL showsBatteryStatus;
@property (retain) NSImage *clockBatteryImage;
@property (retain) NSImage *clockBatteryChargingImage;
@end

@implementation ClockInternalWidget
- (void)commonInit
{
    self.clockBatteryImage = [NSImage imageNamed:@"ClockBattery"];
    self.clockBatteryChargingImage = [NSImage imageNamed:@"ClockBattery"];

    self.customizationLabel = @"Clock";
    ImageTitleView *view = [[[ClockWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    view.wantsLayer = YES;
    view.layer.cornerRadius = 8.0;
    view.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];
    view.imageSize = NSMakeSize(15, 30);
    view.titleLineBreakMode = NSLineBreakByTruncatingTail;
    view.subtitleFont = [NSFont systemFontOfSize:[NSFont
        systemFontSizeForControlSize:NSControlSizeSmall]];
    view.subtitleLineBreakMode = NSLineBreakByTruncatingTail;
    view.layoutOptions = ImageTitleViewLayoutOptionTitle;
    self.view = view;

    self.formatter = [[[NSDateFormatter alloc] init] autorelease];
    self.formatter.dateFormat = @"h:mm a";

    [PowerStatus sharedInstance];
}

- (void)dealloc
{
    self.clockBatteryImage = nil;
    self.clockBatteryChargingImage = nil;

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
    ImageTitleView *view = self.view;

    if (!self.showsBatteryStatus)
    {
        view.image = nil;
        view.titleFont = [NSFont systemFontOfSize:0];
        view.title = [self.formatter stringFromDate:[NSDate date]];
        view.layoutOptions = ImageTitleViewLayoutOptionTitle;
    }
    else
    {
        NSDictionary *info = [[PowerStatus sharedInstance] providingSourceInfoDictionary];
        NSNumber *currentCapacity = [info objectForKey:PowerStatusCurrentCapacity];
        NSNumber *maxCapacity = [info objectForKey:PowerStatusMaxCapacity];
        double capacity = 100 * [currentCapacity doubleValue] / [maxCapacity doubleValue];
        BOOL charging = [[info objectForKey:PowerStatusIsCharging] boolValue];

        view.image = charging ? self.clockBatteryChargingImage : self.clockBatteryImage;
        view.titleFont = [NSFont systemFontOfSize:[NSFont
            systemFontSizeForControlSize:NSControlSizeSmall]];
        view.title = [self.formatter stringFromDate:[NSDate date]];
        view.subtitle = isnan(capacity) || isinf(capacity) ?
            @"--" :
            [NSString stringWithFormat:@"%.0f%%", capacity];
        view.layoutOptions =
            ImageTitleViewLayoutOptionImage |
            ImageTitleViewLayoutOptionTitle |
            ImageTitleViewLayoutOptionSubtitle;
    }
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

- (BOOL)showsBatteryStatus
{
    ClockInternalWidget *widget = (id)[self.widgets objectAtIndex:0];
    return widget.showsBatteryStatus;
}

- (void)setShowsBatteryStatus:(BOOL)value
{
    ClockInternalWidget *widget = (id)[self.widgets objectAtIndex:0];
    widget.showsBatteryStatus = value;
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
