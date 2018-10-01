/**
 * @file TouchBarController.m
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

#import "TouchBarController.h"
#import "NSTouchBar+SystemModal.h"

@implementation TouchBarController
+ (id)controllerWithNibNamed:(NSString *)name
{
    id controller = [[[[self class] alloc] init] autorelease];
    NSArray *objects = nil;

    if (![[NSBundle mainBundle]
        loadNibNamed:name owner:controller topLevelObjects:&objects])
        return nil;

    return controller;
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
    if (self.presented)
        return NO;
    BOOL res = [NSTouchBar
        presentSystemModal:self.touchBar
        placement:placement
        systemTrayItemIdentifier:nil];
    if (res)
        self.presented = YES;
    return res;
}

- (void)dismiss
{
    if (!self.presented)
        return;
    [NSTouchBar
        dismissSystemModal:self.touchBar];
    self.presented = NO;
}

- (IBAction)close:(id)sender
{
    [self dismiss];
}

- (IBAction)customize:(id)sender
{
    NSApp.touchBar = self.touchBar;
    [self performSelector:@selector(delayedCustomize) withObject:nil afterDelay:0];
}

- (void)delayedCustomize
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
    [[NSNotificationCenter defaultCenter]
        removeObserver:self
        name:@"NSTouchBarWillEnterCustomization"
        object:nil];
    [[NSNotificationCenter defaultCenter]
        removeObserver:self
        name:@"NSTouchBarDidExitCustomization"
        object:nil];

    NSApp.touchBar = nil;
    [self present];
}
@end
