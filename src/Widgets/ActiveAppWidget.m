/**
 * @file ActiveAppWidget.m
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

#import "ActiveAppWidget.h"
#import "FixedSizeLabel.h"

@implementation ActiveAppWidget
- (void)commonInit
{
    self.customizationLabel = @"Active App";

    FixedSizeLabel *label = [FixedSizeLabel labelWithString:@"Active App"];
    label.wantsLayer = YES;
    label.layer.cornerRadius = 8.0;
    label.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];
    label.alignment = NSTextAlignmentCenter;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    self.view = label;

    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(didActivateApplication:)
        name:NSWorkspaceDidActivateApplicationNotification
        object:nil];
}

- (void)dealloc
{
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        removeObserver:self];

    [super dealloc];
}

- (void)viewWillAppear
{
    [self reset];
}

- (void)didActivateApplication:(NSNotification *)notification
{
    [self reset];
}

- (void)reset
{
    NSRunningApplication *app = [[NSWorkspace sharedWorkspace] menuBarOwningApplication];
    if (nil != app)
    {
        FixedSizeLabel *label = self.view;
        label.stringValue = app.localizedName;
    }
}
@end
