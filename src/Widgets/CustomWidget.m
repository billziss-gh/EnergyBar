/**
 * @file CustomWidget.m
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

#import "CustomWidget.h"

@interface CustomWidget_ViewController : NSViewController
@property (assign) CustomWidget *widget;
@end

@implementation CustomWidget_ViewController
- (void)viewWillAppear
{
    [self.widget viewWillAppear];
}
- (void)viewWillDisappear
{
    [self.widget viewWillDisappear];
}
@end

@implementation CustomWidget
- (id)initWithIdentifier:(NSTouchBarItemIdentifier)identifier
{
    self = [super initWithIdentifier:identifier];
    if (nil == self)
        return nil;
    
    [self commonInit_];

    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (nil == self)
        return nil;
    
    [self commonInit_];

    return self;
}

- (void)commonInit_
{
    CustomWidget_ViewController *controller = [[[CustomWidget_ViewController alloc] init]
        autorelease];
    controller.widget = self;
    self.viewController = controller;

    [self commonInit];
}

- (void)commonInit
{
}

- (void)viewWillAppear
{
}

- (void)viewWillDisappear
{
}

- (void)setView:(NSView *)view
{
    self.viewController.view = view;
}
@end
