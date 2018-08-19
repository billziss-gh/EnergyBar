/**
 * @file TouchBarController.m
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

#import "TouchBarController.h"
#import "TouchBarPrivate.h"

@implementation TouchBarController
- (void)dealloc
{
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        removeObserver:self];

    self.touchBar = nil;

    [super dealloc];
}

- (BOOL)present
{
    return [self presentWithPlacement:1];
}

- (BOOL)presentWithPlacement:(NSInteger)placement
{
    return [NSTouchBar
        presentSystemModal:self.touchBar
        placement:placement
        systemTrayItemIdentifier:nil];
}

- (void)dismiss
{
    return [NSTouchBar
        dismissSystemModal:self.touchBar];
}

- (IBAction)customize:(id)sender
{
    NSApp.touchBar = self.touchBar;
    [self performSelector:@selector(delayedCustomize) withObject:nil afterDelay:0];
}

- (IBAction)delayedCustomize
{
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(willEnterCustomization:)
        name:@"NSTouchBarWillEnterCustomization"
        object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(didExitCustomization:)
        name:@"NSTouchBarDidExitCustomization"
        object:nil];

    [NSApp toggleTouchBarCustomizationPalette:self];
}

- (void)willEnterCustomization:(NSNotification *)notification
{
    [self dismiss];
}

- (void)didExitCustomization:(NSNotification *)notification
{
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        removeObserver:self
        name:@"NSTouchBarWillEnterCustomization"
        object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        removeObserver:self
        name:@"NSTouchBarDidExitCustomization"
        object:nil];

    NSApp.touchBar = nil;
    [self present];
}
@end
