/**
 * @file TrashcanWidget.m
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

#import "TrashcanWidget.h"
#import "NSWorkspace+Trashcan.h"

@interface TrashcanWidgetButton : NSButton
@end

@implementation TrashcanWidgetButton
- (NSSize)intrinsicContentSize
{
    NSSize size = [super intrinsicContentSize];
    size.width = MIN(size.width, 64);
    return size;
}
@end

@implementation TrashcanWidget
- (void)commonInit
{
    self.customizationLabel = @"Trash";
    NSButton *button = [TrashcanWidgetButton
        buttonWithImage:[NSImage imageNamed:@"TrashEmpty"]
        target:self
        action:@selector(click:)];
    button.bordered = NO;
    self.view = button;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)click:(id)sender
{
    [[NSWorkspace sharedWorkspace] openTrashcan];
}
@end
