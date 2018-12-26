/**
 * @file TouchBarController.h
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

#import <Cocoa/Cocoa.h>

@interface TouchBarController : NSObject
+ (id)controllerWithNibNamed:(NSString *)name;
- (BOOL)isPresented;
- (BOOL)present;
- (BOOL)presentWithPlacement:(NSInteger)placement;
- (void)dismiss;
- (void)minimize;
- (IBAction)close:(id)sender;
- (IBAction)customize:(id)sender;
@property (retain) IBOutlet NSTouchBar *touchBar;
@property (assign) NSInteger placement;
@end
