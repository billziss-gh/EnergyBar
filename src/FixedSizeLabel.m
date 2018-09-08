/**
 * @file FixedSizeLabel.m
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

#import "FixedSizeLabel.h"

@interface FixedSizeLabelCell : NSTextFieldCell
@end

@implementation FixedSizeLabelCell
- (NSFont *)font
{
    NSFont *systemFont = [NSFont systemFontOfSize:0];
    NSSize fixedSize = [(id)self.controlView fixedSize];
    NSSize titleSize = [self.stringValue sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName,
        nil]];
    return fixedSize.width >= titleSize.width ?
        systemFont :
        [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]];
}

- (NSRect)drawingRectForBounds:(NSRect)rect
{
    NSRect drawingRect = [super drawingRectForBounds:rect];
    NSSize size = [super cellSizeForBounds:rect];
    if (drawingRect.size.height > size.height)
        drawingRect.origin.y = (drawingRect.size.height - size.height) / 2;
    return drawingRect;
}
@end

@implementation FixedSizeLabel
+ (void)load
{
    [FixedSizeLabel setCellClass:[FixedSizeLabelCell class]];
}

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
    return self.fixedSize;
}
@end
