/**
 * @file WeatherKit.h
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

#import <Cocoa/Cocoa.h>

@interface WMWeatherData : NSObject
+ (id)temperatureUnitsBasedOnLocale;
+ (id)temperatureStringBasedOnLocaleGivenCelsius:(double)c fahrenheit:(double)f;
+ (double)temperatureBasedOnLocaleGivenCelsius:(double)c fahrenheit:(double)f;
+ (double)temperatureInFahrenheitGivenCelsius:(double)c;
- (id)naturalLanguageString:(BOOL)arg1;
@property float chanceOfPrecipitation;
@property unsigned long long conditionCode;
@property(copy) NSString *conditionLocalizedString;
@property struct CLLocationCoordinate2D coordinate;
@property(copy) NSDate *creationDate;
@property(copy) id location;
@property(copy) NSURL *imageSmallURL;
@property(copy) NSURL *imageLargeURL;
@property(copy) NSString *naturalLanguageStringCelsius;
@property(copy) NSString *naturalLanguageStringFahrenheit;
@property(copy) NSDate *sunriseDate;
@property(copy) NSDate *sunsetDate;
@property(copy) NSDateComponents *representedDate;
@property(readonly) double temperatureBasedOnLocale;
@property double temperatureCelsius;
@property(readonly) double temperatureFahrenheit;
@property(readonly) double temperatureHighBasedOnLocale;
@property double temperatureHighCelsius;
@property(copy) NSColor *temperatureHighColor;
@property(readonly) double temperatureHighFahrenheit;
@property(readonly) double temperatureLowBasedOnLocale;
@property double temperatureLowCelsius;
@property(copy) NSColor *temperatureLowColor;
@property(readonly) double temperatureLowFahrenheit;
@property(readonly, retain) NSString *temperatureStringBasedOnLocale;
@property(readonly, retain) NSString *temperatureStringHighBasedOnLocale;
@property(readonly, retain) NSString *temperatureStringHighLowBasedOnLocale;
@property(readonly, retain) NSString *temperatureStringLowBasedOnLocale;
@property unsigned long long weatherDataType;
@end

@interface WMWeatherStore : NSObject
+ (id)sharedWeatherStore;
- (void)currentConditionsForCoordinate:(struct CLLocationCoordinate2D)coord
    result:(void (^)(WMWeatherData *))block;
- (void)currentHourlyForecastForCoordinate:(struct CLLocationCoordinate2D)coord
    result:(void (^)(WMWeatherData *))block;
- (void)currentDailyForecastForCoordinate:(struct CLLocationCoordinate2D)coord
    result:(void (^)(WMWeatherData *))block;
- (void)forecastForCoordinate:(struct CLLocationCoordinate2D)coord
    atDate:(NSDateComponents *)comp
    result:(void (^)(WMWeatherData *))block;
- (void)historicalWeatherForCoordinate:(struct CLLocationCoordinate2D)coord
    atDate:(NSDateComponents *)comp
    result:(void (^)(WMWeatherData *))block;
- (void)almanacWeatherForCoordinate:(struct CLLocationCoordinate2D)coord
    atDate:(NSDateComponents *)comp
    result:(void (^)(WMWeatherData *))block;
- (void)weatherForCoordinate:(struct CLLocationCoordinate2D)coord
    atDate:(NSDateComponents *)comp
    result:(void (^)(WMWeatherData *))block;
@end
