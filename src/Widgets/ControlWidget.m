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
#import "KeyEvent.h"
#import "TouchBarPrivate.h"

@interface ControlWidgetBrightnessBarController : NSObject
- (BOOL)present;
- (void)dismiss;
@property (retain) IBOutlet NSTouchBar *touchBar;
@end

@implementation ControlWidgetBrightnessBarController
+ (id)controller
{
    id controller = [[[ControlWidgetBrightnessBarController alloc] init] autorelease];
    NSArray *objects = nil;

    if (![[NSBundle mainBundle]
        loadNibNamed:@"BrightnessBar" owner:controller topLevelObjects:&objects])
        return nil;

    return controller;
}

- (BOOL)present
{
    return [NSTouchBar
        presentSystemModal:self.touchBar
        placement:1
        systemTrayItemIdentifier:nil];
}

- (void)dismiss
{
    return [NSTouchBar
        dismissSystemModal:self.touchBar];
}
@end

@interface ControlWidgetVolumeBarController : NSObject
- (BOOL)present;
- (void)dismiss;
@property (retain) IBOutlet NSTouchBar *touchBar;
@end

@implementation ControlWidgetVolumeBarController
+ (id)controller
{
    id controller = [[[ControlWidgetVolumeBarController alloc] init] autorelease];
    NSArray *objects = nil;

    if (![[NSBundle mainBundle]
        loadNibNamed:@"VolumeBar" owner:controller topLevelObjects:&objects])
        return nil;

    return controller;
}

- (BOOL)present
{
    return [NSTouchBar
        presentSystemModal:self.touchBar
        placement:1
        systemTrayItemIdentifier:nil];
}

- (void)dismiss
{
    return [NSTouchBar
        dismissSystemModal:self.touchBar];
}
@end

@interface ControlWidget ()
@property (retain) ControlWidgetBrightnessBarController *brightnessBarController;
@property (retain) ControlWidgetVolumeBarController *volumeBarController;
@end

@implementation ControlWidget
- (void)commonInit
{
    self.brightnessBarController = [ControlWidgetBrightnessBarController controller];
    self.volumeBarController = [ControlWidgetVolumeBarController controller];

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
    self.brightnessBarController = nil;
    self.volumeBarController = nil;

    [super dealloc];
}

- (void)click:(id)sender
{
    NSSegmentedControl *control = sender;
    switch (control.selectedSegment)
    {
    case 0:
        break;
    case 1:
        [self.brightnessBarController present];
        break;
    case 2:
        [self.volumeBarController present];
        break;
    case 3:
        PostAuxKeyPress(NX_KEYTYPE_MUTE);
        break;
    }
}
@end
