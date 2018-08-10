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
- (id)init
{
    self = [super init];
    if (nil == self)
        return nil;

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

    return self;
}

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
    [NSApp toggleTouchBarCustomizationPalette:self];
}

- (void)willEnterCustomization:(NSNotification *)notification
{
    [self dismiss];
}

- (void)didExitCustomization:(NSNotification *)notification
{
    [self present];
}
@end
