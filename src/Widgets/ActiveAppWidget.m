/**
 * @file ActiveAppWidget.m
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

#import "ActiveAppWidget.h"

@interface ActiveAppWidgetLabel : NSTextField
@end

@implementation ActiveAppWidgetLabel
- (NSSize)intrinsicContentSize
{
    NSSize size = [super intrinsicContentSize];
    size.width = MAX(size.width, 150);
    return size;
}
@end

@implementation ActiveAppWidget
- (void)commonInit
{
    self.customizationLabel = @"Active App";

    ActiveAppWidgetLabel *label = [ActiveAppWidgetLabel labelWithString:@"Active App"];
    label.alignment = NSTextAlignmentRight;
    self.view = label;
}

- (void)dealloc
{
    [super dealloc];
}
@end
