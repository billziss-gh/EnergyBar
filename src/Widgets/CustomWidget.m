/**
 * @file CustomWidget.m
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

#import "CustomWidget.h"

@interface CustomWidgetViewController : NSViewController
@property (assign) CustomWidget *widget;
@end

@implementation CustomWidgetViewController
- (void)viewWillAppear
{
    [self.widget viewWillAppear];
}

- (void)viewDidAppear
{
    [self.widget viewDidAppear];
}

- (void)viewWillDisappear
{
    [self.widget viewWillDisappear];
}

- (void)viewDidDisappear
{
    [self.widget viewDidDisappear];
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
    CustomWidgetViewController *controller = [[[CustomWidgetViewController alloc] init]
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

- (void)viewDidAppear
{
}

- (void)viewWillDisappear
{
}

- (void)viewDidDisappear
{
}

- (void)setView:(NSView *)view
{
    self.viewController.view = view;
}
@end
