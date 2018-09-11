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

@interface CustomMultiWidgetView : NSView
@property (assign) CustomMultiWidget *owner;
@end

@implementation CustomMultiWidgetView
- (void)layout
{
    [super layout];

    NSRect bounds = self.bounds;
    [self.owner.widgets enumerateObjectsUsingBlock:^(NSTouchBarItem *widget, NSUInteger idx, BOOL *stop)
    {
        NSSize size = [widget.view intrinsicContentSize];
        size.width = MIN(bounds.size.width, size.width);
        size.height = MIN(bounds.size.height, size.height);
        widget.view.frame = NSMakeRect(
            NSViewNoIntrinsicMetric != size.width ? (bounds.size.width - size.width) / 2 : 0,
            NSViewNoIntrinsicMetric != size.height ? (bounds.size.height - size.height) / 2 : 0,
            NSViewNoIntrinsicMetric != size.width ? size.width : bounds.size.width,
            NSViewNoIntrinsicMetric != size.height ? size.height : bounds.size.height);
    }];
}

- (NSSize)intrinsicContentSize
{
    __block CGFloat maxwidth = NSViewNoIntrinsicMetric;
    [self.owner.widgets enumerateObjectsUsingBlock:^(NSTouchBarItem *widget, NSUInteger idx, BOOL *stop)
    {
        NSSize size = [widget.view intrinsicContentSize];
        if (maxwidth < size.width)
            maxwidth = size.width;
    }];
    return NSMakeSize(maxwidth, NSViewNoIntrinsicMetric);
}
@end

@implementation CustomMultiWidget
{
    NSMutableArray<NSTouchBarItem *> *_widgets;
}

- (void)commonInit_
{
    CustomWidgetViewController *controller = [[[CustomWidgetViewController alloc] init]
        autorelease];
    controller.widget = self;
    self.viewController = controller;

    _widgets = [[NSMutableArray alloc] init];

    CustomMultiWidgetView *view = [[[CustomMultiWidgetView alloc]
        initWithFrame:NSZeroRect] autorelease];
    view.owner = self;
    NSClickGestureRecognizer *tapRecognizer = [[[NSClickGestureRecognizer alloc]
        initWithTarget:self action:@selector(tapAction_:)] autorelease];
    tapRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    NSPressGestureRecognizer *longPressRecognizer = [[[NSPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(longPressAction_:)] autorelease];
    longPressRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    longPressRecognizer.minimumPressDuration = LongPressDuration;
    [view addGestureRecognizer:tapRecognizer];
    [view addGestureRecognizer:longPressRecognizer];
    self.view = view;

    [self commonInit];

    NSTouchBarItem *primaryWidget = [_widgets firstObject];
    self.customizationLabel = [primaryWidget customizationLabel];
}

- (void)dealloc
{
    [_widgets release];

    [super dealloc];
}

- (NSArray<NSTouchBarItem *> *)widgets
{
    return _widgets;
}

- (NSUInteger)activeIndex
{
    for (NSUInteger index = 0, count = _widgets.count; count > index; index++)
    {
        NSTouchBarItem *widget = [_widgets objectAtIndex:index];
        if (widget.view.superview == self.view)
            return index;
    }

    return NSNotFound;
}

- (void)setActiveIndex:(NSUInteger)value
{
    if (self.activeIndex == value)
        return;

    [[self.view.subviews firstObject] removeFromSuperview];
    if (value < _widgets.count)
        [self.view addSubview:[[_widgets objectAtIndex:value] view]];
}

- (void)addWidget:(NSTouchBarItem *)widget
{
    [_widgets addObject:widget];
    [self.view invalidateIntrinsicContentSize];

    if (NSNotFound == self.activeIndex)
        self.activeIndex = 0;
}

- (void)removeWidgetWithIdentifier:(NSString *)identifier
{
    for (NSUInteger index = 0, count = _widgets.count; count > index; index++)
    {
        NSTouchBarItem *widget = [_widgets objectAtIndex:index];
        if ([widget.identifier isEqualToString:identifier])
        {
            [widget.view removeFromSuperview];
            [_widgets removeObjectAtIndex:index];
            [self.view invalidateIntrinsicContentSize];
            break;
        }
    }

    if (NSNotFound == self.activeIndex)
        self.activeIndex = 0;
}

- (void)tapAction_:(NSGestureRecognizer *)recognizer
{
    if (NSGestureRecognizerStateRecognized != recognizer.state)
        return;

    [self tapAction:self];
}

- (void)tapAction:(id)sender
{
    self.activeIndex = (self.activeIndex + 1) % _widgets.count;
}

- (void)longPressAction_:(NSGestureRecognizer *)recognizer
{
    if (NSGestureRecognizerStateBegan != recognizer.state)
        return;

    [self longPressAction:self];
}

- (void)longPressAction:(id)sender
{
    NSTouchBarItem *primaryWidget = [_widgets firstObject];
    if ([primaryWidget respondsToSelector:@selector(longPressAction:)])
        [(id)primaryWidget longPressAction:sender];
}
@end
