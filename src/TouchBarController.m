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
{
    NSCustomTouchBarItem *_button;
}
+ (id)controllerWithNibNamed:(NSString *)name
{
    id controller = [[[[self class] alloc] init] autorelease];
    NSArray *objects = nil;

    if (![[NSBundle mainBundle]
        loadNibNamed:name owner:controller topLevelObjects:&objects])
        return nil;
    
    DFRSystemModalShowsCloseBoxWhenFrontMost(YES);
    [controller setPlacement:1];

    return controller;
}

- (id)init
{
    if (self = [super init]) {
        _button = [[[NSCustomTouchBarItem alloc] initWithIdentifier:kControlButtonIdentifier] autorelease];
        [self setControlButton:self action:@selector(present)];
    }
    return self;
}

- (void)dealloc
{
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        removeObserver:self];

    self.touchBar = nil;

    [super dealloc];
}

- (void)setControlButton:(id)target action:(SEL)action
{
    _button.view = [NSButton buttonWithImage:[NSImage imageNamed:@"AppIcon"] target:target action:action];
    [NSTouchBarItem addSystemTrayItem:_button];
    DFRElementSetControlStripPresenceForIdentifier(kControlButtonIdentifier, YES);
}

- (BOOL)isPresented
{
    return [self.touchBar isVisible];
}

- (BOOL)present
{
    return [self presentWithPlacement:self.placement];
}

- (BOOL)presentWithPlacement:(NSInteger)placement
{
    BOOL res = [NSTouchBar
        presentSystemModal:self.touchBar
        placement:placement
        systemTrayItemIdentifier:kControlButtonIdentifier];
    return res;
}

- (void)dismiss
{
    [NSTouchBar
        dismissSystemModal:self.touchBar];
}

- (void)minimize
{
    [NSTouchBar minimizeSystemModal:self.touchBar];
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
