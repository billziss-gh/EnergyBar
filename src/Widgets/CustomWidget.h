/**
 * @file CustomWidget.h
 *
 * @copyright 2018-2019 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import <Cocoa/Cocoa.h>

#define ShortPressDuration              0.1
#define LongPressDuration               0.1
#define SuperLongPressDuration          0.2

@interface CustomWidget : NSCustomTouchBarItem
- (void)commonInit;
- (void)viewWillAppear;
- (void)viewDidAppear;
- (void)viewWillDisappear;
- (void)viewDidDisappear;
@end

@interface CustomMultiWidget : CustomWidget
@property (readonly, getter=widgets) NSArray<NSTouchBarItem *> *widgets;
@property (getter=activeIndex, setter=setActiveIndex:) NSUInteger activeIndex;
- (void)addWidget:(NSTouchBarItem *)widget;
- (void)removeWidgetWithIdentifier:(NSString *)identifier;
- (NSTouchBarItem *)widgetWithIdentifier:(NSString *)identifier;
- (void)tapAction:(id)sender;
- (void)longPressAction:(id)sender;
- (void)superLongPressAction:(id)sender;
@end
