/**
 * @file NSView+TouchBarHitTest.m
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

#import "NSView+TouchBarHitTest.h"
#import "NSObject+MethodSwizzling.h"

@interface NSView ()
- (BOOL)isHitTestAlwaysEnabled_;
@end

@implementation NSView (TouchBarHitTest)
+ (void)loadTouchBarHitTest
{
    static BOOL done;
    if (!done)
    {
        [self
            swizzleInstanceMethod:@selector(hitTest:)
            withMethod:@selector(__swizzle__hitTest:)];
        done = YES;
    }
}

static int enableTouchBarHitTest;
+ (void)enableTouchBarHitTest:(id)flag
{
    if (flag)
        enableTouchBarHitTest++;
    else
        enableTouchBarHitTest--;
}

- (NSView *)__swizzle__hitTest:(NSPoint)point
{
    if (0 <= enableTouchBarHitTest || [NSWindow class] == [self.window class])
        return [self __swizzle__hitTest:point];

    NSView *hitTestView = [self __swizzle__hitTest:point];
    for (NSView *view = hitTestView; nil != view; view = view.superview)
        if ([view respondsToSelector:@selector(isHitTestAlwaysEnabled_)] &&
            [view isHitTestAlwaysEnabled_])
            return hitTestView;

    return nil;
}
@end
