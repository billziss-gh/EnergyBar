/**
 * @file ControlWidget.m
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

#import "ControlWidget.h"

@implementation ControlWidget
- (void)commonInit
{
    self.customizationLabel = @"Control";
    self.view = [NSSegmentedControl
        segmentedControlWithImages:[NSArray arrayWithObjects:
            [NSImage imageNamed:NSImageNameTouchBarPlayTemplate],
            [NSImage imageNamed:@"BrightnessUp"],
            [NSImage imageNamed:NSImageNameTouchBarAudioOutputVolumeHighTemplate],
            [NSImage imageNamed:NSImageNameTouchBarAudioOutputMuteTemplate],
            nil]
        trackingMode:NSSegmentSwitchTrackingMomentary
        target:self
        action:@selector(click:)];
}

- (void)dealloc
{
    [super dealloc];
}

- (void)click:(id)sender
{
    NSLog(@"%@", sender);
}
@end
