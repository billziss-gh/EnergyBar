/**
 * @file EscKeyWidget.m
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

#import "EscKeyWidget.h"

@interface EscKeyWidget_Button : NSButton
@end

@implementation EscKeyWidget_Button
- (NSSize)intrinsicContentSize
{
    NSSize size = [super intrinsicContentSize];
    size.width = MIN(size.width, 64);
    return size;
}
@end

@implementation EscKeyWidget
- (void)commonInit
{
    self.customizationLabel = @"Esc Key";
    self.view = [EscKeyWidget_Button buttonWithTitle:@"esc" target:self action:@selector(click:)];
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
