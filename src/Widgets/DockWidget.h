/**
 * @file DockWidget.h
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

#import <Cocoa/Cocoa.h>
#import "CustomWidget.h"

@interface DockWidget : CustomWidget
- (NSString *)appsFolder;
- (void)setAppsFolder:(NSString *)path;
@end
