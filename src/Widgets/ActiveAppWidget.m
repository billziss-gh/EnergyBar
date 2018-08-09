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

@implementation ActiveAppWidget
- (void)commonInit
{
    self.customizationLabel = @"Active App";

    self.view = [NSTextField labelWithString:@"Active App"];
}

- (void)dealloc
{
    [super dealloc];
}
@end
