/**
 * @file DockWidget.m
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

#import "DockWidget.h"

@implementation DockWidget
- (void)commonInit
{
    self.customizationLabel = @"Dock";
    self.view = [NSTextField labelWithString:@"DOCK"];
}

- (void)dealloc
{
    [super dealloc];
}

- (void)viewWillAppear
{
}

- (void)viewWillDisappear
{
}
@end
