/**
 * @file ImageTitleView.m
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

#import "ImageTitleView.h"

static const CGFloat DefaultSpacerWidth = 4;

@interface ImageTitleView ()
@property (retain) NSImageView *imageView;
@property (retain) NSTextField *titleView;
@end

@implementation ImageTitleView
{
    NSSize _imageSize;
    NSCellImagePosition _imagePosition;
}

- (id)initWithFrame:(NSRect)rect
{
    self = [super initWithFrame:rect];
    if (nil == self)
        return nil;

    self.imageView = [[[NSImageView alloc] initWithFrame:NSZeroRect] autorelease];
    self.imageView.autoresizingMask = 0;
    self.imageView.imageScaling = NSImageScaleProportionallyDown;

    self.titleView = [NSTextField labelWithString:@""];
    self.titleView.autoresizingMask = 0;
    self.titleView.alignment = NSTextAlignmentLeft;

    [self addSubview:self.imageView];
    [self addSubview:self.titleView];

    return self;
}

- (void)dealloc
{
    self.imageView = nil;
    self.titleView = nil;

    [super dealloc];
}

- (NSImage *)image
{
    return self.imageView.image;
}

- (void)setImage:(NSImage *)value
{
    self.imageView.image = value;
    //[self setNeedsLayout:YES];
}

- (NSSize)imageSize
{
    return _imageSize;
}

- (void)setImageSize:(NSSize)value
{
    if (_imageSize.width == value.width && _imageSize.height == value.height)
        return;

    _imageSize = value;
    [self setNeedsLayout:YES];
}

- (NSCellImagePosition)imagePosition
{
    return _imagePosition;
}

- (void)setImagePosition:(NSCellImagePosition)value
{
    if (_imagePosition == value)
        return;

    _imagePosition = value;
    [self setNeedsLayout:YES];
}

- (NSString *)title
{
    return self.titleView.stringValue;
}

- (void)setTitle:(NSString *)value
{
    if (nil == value)
        value = @"";
    self.titleView.stringValue = value;
    [self setNeedsLayout:YES];
}

- (NSFont *)titleFont
{
    return self.titleView.font;
}

- (void)setTitleFont:(NSFont *)value
{
    self.titleView.font = value;
    [self setNeedsLayout:YES];
}

- (NSLineBreakMode)titleLineBreakMode
{
    return self.titleView.lineBreakMode;
}

- (void)setTitleLineBreakMode:(NSLineBreakMode)value
{
    self.titleView.lineBreakMode = value;
    [self setNeedsLayout:YES];
}

- (void)layout
{
    [super layout];

    NSRect bounds = self.bounds;
    BOOL showsImage = NSNoImage != _imagePosition;
    BOOL showsTitle = NSImageOnly != _imagePosition;
    NSSize imageSize = showsImage && nil != self.image ? _imageSize : NSZeroSize;
    NSSize titleSize = showsTitle ? [self.titleView.cell cellSizeForBounds:bounds] : NSZeroSize;
    CGFloat spacerWidth = 0 != imageSize.width && 0 != titleSize.width ? DefaultSpacerWidth : 0;
    if (titleSize.width > bounds.size.width - (imageSize.width + spacerWidth))
        titleSize.width = bounds.size.width - (imageSize.width + spacerWidth);
    CGFloat totalWidth = imageSize.width + spacerWidth + titleSize.width;
    NSRect imageRect = NSMakeRect(
        (bounds.size.width - totalWidth) / 2,
        (bounds.size.height - imageSize.height) / 2,
        imageSize.width,
        imageSize.height);
    NSRect titleRect = NSMakeRect(
        imageRect.origin.x + imageSize.width + spacerWidth,
        (bounds.size.height - titleSize.height) / 2,
        titleSize.width,
        titleSize.height);

    self.imageView.frame = imageRect;
    self.titleView.frame = titleRect;
}
@end
