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
    return NSMakeSize(100, NSViewNoIntrinsicMetric);
}
@end

@interface ClockInternalWidget : CustomWidget
@property (retain) NSImage *clockBatteryImage;
@property (retain) NSImage *clockBatteryChargingImage;
@property (retain) NSImage *clockBatteryChargedImage;
@property (retain) NSDateFormatter *formatter;
@property (retain) NSTimer *timer;
@property (assign) BOOL showsBatteryStatus;
@property (assign) BOOL showsBatteryTimeRemaining;
@end

@implementation ClockInternalWidget
- (void)commonInit
{
    self.clockBatteryImage = [NSImage imageNamed:@"ClockBattery"];
    self.clockBatteryChargingImage = [NSImage imageNamed:@"ClockBatteryCharging"];
    self.clockBatteryChargedImage = [NSImage imageNamed:@"ClockBatteryCharged"];
    self.formatter = [[[NSDateFormatter alloc] init] autorelease];
    self.formatter.dateFormat = @"h:mm a";

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

    [PowerStatus sharedInstance];
}

- (void)dealloc
{
    [self.timer invalidate];
    self.timer = nil;

    [[NSNotificationCenter defaultCenter]
        removeObserver:self];

    self.clockBatteryImage = nil;
    self.clockBatteryChargingImage = nil;
    self.clockBatteryChargedImage = nil;
    self.formatter = nil;

    [super dealloc];
}

- (void)viewWillAppear
{
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(powerStatusNotification:)
        name:PowerStatusNotification
        object:nil];

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

- (void)viewDidDisappear
{
    [self.timer invalidate];
    self.timer = nil;

    [[NSNotificationCenter defaultCenter]
        removeObserver:self];
}

- (void)powerStatusNotification:(NSNotification *)notification
{
    [self tick:nil];
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
        //BOOL charging = [[info objectForKey:PowerStatusIsCharging] boolValue];
        BOOL charging = ![[[PowerStatus sharedInstance] providingSource]
            isEqualToString:PowerStatusBatteryPower];
        BOOL charged = [[info objectForKey:PowerStatusIsCharged] boolValue];
        NSTimeInterval timeRemaining = [[PowerStatus sharedInstance] remainingTime];

        NSString *clockString = [self.formatter stringFromDate:[NSDate date]];
        NSString *batteryString = isnan(capacity) || isinf(capacity) ?
            @"--" :
            [NSString stringWithFormat:@"%@%.0f%%", charging ? @"⚡︎" : @"", capacity];
        if (self.showsBatteryTimeRemaining)
            batteryString = [batteryString stringByAppendingFormat:@" (%u:%02u)",
                (unsigned)timeRemaining / 3600, (unsigned)timeRemaining / 60 % 60];

        view.image = charged ?
            self.clockBatteryChargedImage :
            (charging ? self.clockBatteryChargingImage : self.clockBatteryImage);
        view.titleFont = [NSFont systemFontOfSize:[NSFont
            systemFontSizeForControlSize:NSControlSizeSmall]];
        view.title = clockString;
        view.subtitle = batteryString;
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

- (BOOL)showsBatteryTimeRemaining
{
    ClockInternalWidget *widget = (id)[self.widgets objectAtIndex:0];
    return widget.showsBatteryTimeRemaining;
}

- (void)setShowsBatteryTimeRemaining:(BOOL)value
{
    ClockInternalWidget *widget = (id)[self.widgets objectAtIndex:0];
    widget.showsBatteryTimeRemaining = value;
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
