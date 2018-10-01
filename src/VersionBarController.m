/**
 * @file VersionBarController.m
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

#import "VersionBarController.h"

@interface VersionBarController ()
@property (retain) IBOutlet NSTextField *versionLabel;
@end

@implementation VersionBarController
+ (id)controller
{
    return [self controllerWithNibNamed:@"VersionBar"];
}

- (void)dealloc
{
    self.versionLabel = nil;

    [super dealloc];
}

- (void)awakeFromNib
{
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    if (nil != version)
        version = [self.versionLabel.stringValue
            stringByReplacingOccurrencesOfString:@"0.0" withString:version];
    else
        version = @"";
    self.versionLabel.stringValue = version;
}
@end
