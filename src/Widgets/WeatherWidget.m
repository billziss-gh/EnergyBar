/**
 * @file WeatherWidget.m
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

#import "WeatherWidget.h"
#import <CoreLocation/CoreLocation.h>
#import "ImageTitleView.h"
#import "WeatherKit.h"

@interface WeatherData : NSObject
@property (retain) NSImage *icon;
@property (copy) NSString *condition;
@property (copy) NSString *placeName;
@end

@implementation WeatherData
- (void)dealloc
{
    self.icon = nil;
    self.condition = nil;
    self.placeName = nil;

    [super dealloc];
}
@end

@interface WeatherWidgetView : ImageTitleView
@end

@implementation WeatherWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(80, NSViewNoIntrinsicMetric);
}
@end

@interface WeatherWidget () <CLLocationManagerDelegate>
@property (retain) CLLocationManager *manager;
@property (retain) NSTimer *timer;
@end

@implementation WeatherWidget
- (void)commonInit
{
    self.customizationLabel = @"Weather";

    ImageTitleView *view = [[[WeatherWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    view.wantsLayer = YES;
    view.layer.cornerRadius = 8.0;
    view.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];
    view.imageSize = NSMakeSize(20, 20);
    view.titleFont = [NSFont boldSystemFontOfSize:[NSFont
        systemFontSizeForControlSize:NSControlSizeSmall]];
    view.titleLineBreakMode = NSLineBreakByTruncatingTail;
    view.subtitleFont = [NSFont systemFontOfSize:[NSFont
        systemFontSizeForControlSize:NSControlSizeSmall]];
    view.subtitleLineBreakMode = NSLineBreakByTruncatingTail;
    view.layoutOptions = ImageTitleViewLayoutOptionTitle;
    view.title = @"Weather";
    self.view = view;

    self.manager = [[[CLLocationManager alloc] init] autorelease];
}

- (void)dealloc
{
    self.manager = nil;
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

    NSDate *date = [[NSDate date] dateByAddingTimeInterval:3600.0];
    NSDateComponents *comp = [[NSCalendar currentCalendar]
        components:NSCalendarUnitEra|NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|
            NSCalendarUnitHour
        fromDate:date];
    date = [[NSCalendar currentCalendar] dateFromComponents:comp];

    self.timer = [[[NSTimer alloc]
        initWithFireDate:date
        interval:3600.0
        target:self
        selector:@selector(tick:)
        userInfo:nil
        repeats:YES] autorelease];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];

    [self tick:nil];
}

- (void)stop
{
    [self.timer invalidate];
    self.timer = nil;

    [self.manager stopUpdatingLocation];
    self.manager.delegate = nil;
}

- (void)tick:(NSTimer *)sender
{
    [self.manager startUpdatingLocation];
    self.manager.delegate = self;
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    [self.manager stopUpdatingLocation];
    self.manager.delegate = nil;

    CLLocation *location = [locations lastObject];
    CLGeocoder *geocoder = [[[CLGeocoder alloc] init] autorelease];
    [geocoder
        reverseGeocodeLocation:location
        completionHandler:^(NSArray<CLPlacemark *> *placemarks, NSError *error)
        {
            WeatherData *data = [[[WeatherData alloc] init] autorelease];
            data.placeName = [[placemarks firstObject] locality];
            [[WMWeatherStore sharedWeatherStore]
                currentConditionsForCoordinate:location.coordinate
                result:^(WMWeatherData *wmdata)
                {
                    data.icon = [[[NSImage alloc]
                        initWithContentsOfURL:wmdata.imageSmallURL] autorelease];
                    data.condition = [NSString stringWithFormat:@"%.0f%@",
                        'F' == self.temperatureUnit ? wmdata.temperatureFahrenheit : wmdata.temperatureCelsius,
                        'F' == self.temperatureUnit ? @"°F" : @"°C"];
                    [self
                        performSelectorOnMainThread:@selector(updateWeather:)
                        withObject:data
                        waitUntilDone:NO];
                }];
        }];
}

- (void)locationManager:(CLLocationManager *)manager
    didFailWithError:(NSError *)error
{
    switch (error.code)
    {
    case kCLErrorDenied:
        [self.manager stopUpdatingLocation];
        self.manager.delegate = nil;
        [self updateWeather:nil];
        break;
    default:
        break;
    }
}

- (void)updateWeather:(WeatherData *)data
{
    NSImage *icon = data.icon;
    NSString *title = data.condition;
    NSString *subtitle = data.placeName;

    if (nil == icon && nil == title && nil == subtitle)
        title = @"?";

    ImageTitleViewLayoutOptions layoutOptions = 0;
    if (nil != icon)
        layoutOptions = layoutOptions | ImageTitleViewLayoutOptionImage;
    if (nil != title)
        layoutOptions = layoutOptions | ImageTitleViewLayoutOptionTitle;
    if (nil != subtitle)
        layoutOptions = layoutOptions | ImageTitleViewLayoutOptionSubtitle;

    ImageTitleView *view = self.view;
    view.image = icon;
    view.title = title;
    view.subtitle = subtitle;
    view.layoutOptions = layoutOptions;
}

- (void)resetWeather
{
    if (nil == self.timer)
        return;

    [self stop];
    [self start];
}
@end
