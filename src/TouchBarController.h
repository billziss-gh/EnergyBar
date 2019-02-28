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
#import "Widgets/ControlTrayWidget.h"

static const NSTouchBarItemIdentifier kControlButtonIdentifier = @"billziss.energybar.controlbutton";

@interface TouchBarController : NSObject
+ (id)controllerWithNibNamed:(NSString *)name;
- (void)setControlButtonLongPress:(id)target action:(SEL)action;
- (BOOL)isPresented;
- (BOOL)present;
- (BOOL)presentWithPlacement:(NSInteger)placement;
- (void)dismiss;
- (void)minimize;
- (IBAction)close:(id)sender;
- (IBAction)customize:(id)sender;
@property (retain) ControlTrayWidget *button;
@property (retain) IBOutlet NSTouchBar *touchBar;
@property (assign) NSInteger placement;
@end
