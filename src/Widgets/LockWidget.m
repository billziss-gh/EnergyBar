/**
 * @file LockWidget.m
 *
 * @copyright 2018 Brian Hartvigsen
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import "LockWidget.h"
#import "ImageTitleView.h"

void SACLockScreenImmediate(void);

@interface LockWidgetView : ImageTitleView
@end

@implementation LockWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(36, NSViewNoIntrinsicMetric);
}
@end

@implementation LockWidget
- (void)commonInit
{
    self.customizationLabel = @"Lock Screen";
    self.lockImage = [NSImage imageNamed:@"Lock"];
    ImageTitleView *view = [[[LockWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    view.wantsLayer = YES;
    view.layer.cornerRadius = 8.0;
    view.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];
    view.imageSize = NSMakeSize(15, 30);
    view.layoutOptions = ImageTitleViewLayoutOptionImage;
    view.image = self.lockImage;
    
    NSClickGestureRecognizer *tapRecognizer = [[[NSClickGestureRecognizer alloc]
                                                initWithTarget:self action:@selector(tapAction:)] autorelease];
    tapRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    [view addGestureRecognizer:tapRecognizer];
    
    self.view = view;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)tapAction:(id)sender
{
    SACLockScreenImmediate();
}
@end
