/**
 * @file FixedSizeLabel.m
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

#import "FixedSizeLabel.h"

@implementation FixedSizeLabel
- (id)initWithFrame:(NSRect)rect
{
    self = [super initWithFrame:rect];
    if (nil == self)
        return nil;

    self.fixedSize = NSMakeSize(150, NSViewNoIntrinsicMetric);

    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (nil == self)
        return nil;

    self.fixedSize = NSMakeSize(150, NSViewNoIntrinsicMetric);

    return self;
}

- (NSSize)intrinsicContentSize
{
    NSSize size = [super intrinsicContentSize];
    return NSMakeSize(self.fixedSize.width, size.height);
}

- (void)setStringValue:(NSString *)value
{
    [super setStringValue:value];

    NSFont *systemFont = [NSFont systemFontOfSize:0];
    self.font = systemFont;
    NSSize size = [super intrinsicContentSize];
    self.font = self.fixedSize.width >= size.width ?
        systemFont :
        [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]];
}
@end
