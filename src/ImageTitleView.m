/**
 * @file ImageTitleView.m
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

#import "ImageTitleView.h"

static const CGFloat DefaultSpacerWidth = 4;

@interface ImageTitleView ()
@property (retain) NSImageView *imageView;
@property (retain) NSTextField *titleView;
@property (retain) NSTextField *subtitleView;
@end

@implementation ImageTitleView
{
    NSSize _imageSize;
    ImageTitleViewLayoutOptions _layoutOptions;
}

- (id)initWithFrame:(NSRect)rect
{
    self = [super initWithFrame:rect];
    if (nil == self)
        return nil;

    _imageSize = NSMakeSize(30, 30);
    _layoutOptions = 0;

    self.imageView = [[[NSImageView alloc] initWithFrame:NSZeroRect] autorelease];
    self.imageView.autoresizingMask = 0;
    self.imageView.imageScaling = NSImageScaleProportionallyDown;

    self.titleView = [NSTextField labelWithString:@""];
    self.titleView.autoresizingMask = 0;
    self.titleView.alignment = NSTextAlignmentLeft;
    
    self.subtitleView = [NSTextField labelWithString:@""];
    self.subtitleView.autoresizingMask = 0;
    self.subtitleView.alignment = NSTextAlignmentLeft;

    [self addSubview:self.imageView];
    [self addSubview:self.titleView];
    [self addSubview:self.subtitleView];

    return self;
}

- (void)dealloc
{
    self.imageView = nil;
    self.titleView = nil;
    self.subtitleView = nil;

    [super dealloc];
}

- (NSImage *)image
{
    return self.imageView.image;
}

- (void)setImage:(NSImage *)value
{
    self.imageView.image = value;
    [self setNeedsLayout:YES];
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

- (NSString *)subtitle
{
    return self.subtitleView.stringValue;
}

- (void)setSubtitle:(NSString *)value
{
    if (nil == value)
        value = @"";
    self.subtitleView.stringValue = value;
    [self setNeedsLayout:YES];
}

- (NSFont *)subtitleFont
{
    return self.subtitleView.font;
}

- (void)setSubtitleFont:(NSFont *)value
{
    self.subtitleView.font = value;
    [self setNeedsLayout:YES];
}

- (NSLineBreakMode)subtitleLineBreakMode
{
    return self.subtitleView.lineBreakMode;
}

- (void)setSubtitleLineBreakMode:(NSLineBreakMode)value
{
    self.subtitleView.lineBreakMode = value;
    [self setNeedsLayout:YES];
}

- (ImageTitleViewLayoutOptions)layoutOptions
{
    return _layoutOptions;
}

- (void)setLayoutOptions:(ImageTitleViewLayoutOptions)layoutOptions
{
    _layoutOptions = layoutOptions;
    [self setNeedsLayout:YES];
}

- (void)layout
{
    [super layout];

    NSRect bounds = self.bounds;
    BOOL showsImage = !!(_layoutOptions & ImageTitleViewLayoutOptionImage);
    BOOL showsTitle = !!(_layoutOptions & ImageTitleViewLayoutOptionTitle);
    BOOL showsSubtitle = !!(_layoutOptions & ImageTitleViewLayoutOptionSubtitle);
    NSSize imageSize = showsImage && nil != self.image ? _imageSize : NSZeroSize;
    NSSize titleSize = showsTitle ? [self.titleView.cell cellSizeForBounds:bounds] : NSZeroSize;
    NSSize subtitleSize = showsSubtitle ? [self.subtitleView.cell cellSizeForBounds:bounds] : NSZeroSize;
    CGFloat spacerWidth = 0 != imageSize.width && (0 != titleSize.width || 0 != subtitleSize.width) ?
        DefaultSpacerWidth : 0;
    CGFloat imageSpacerWidth = imageSize.width + spacerWidth;
    
    /* stop the labels from going out of bounds */
    titleSize.width = MIN(titleSize.width, bounds.size.width - imageSpacerWidth);
    subtitleSize.width = MIN(subtitleSize.width, bounds.size.width - imageSpacerWidth);

    CGFloat totalWidth = imageSpacerWidth + MAX(titleSize.width, subtitleSize.width);
    NSRect imageRect = NSMakeRect(
        round((bounds.size.width - totalWidth) / 2),
        round((bounds.size.height - imageSize.height) / 2),
        imageSize.width,
        imageSize.height);
    NSRect titleRect = NSMakeRect(
        round(imageRect.origin.x + imageSpacerWidth),
        round((bounds.size.height - titleSize.height + subtitleSize.height) / 2),
        titleSize.width,
        titleSize.height);
    NSRect subtitleRect = NSMakeRect(
        round(imageRect.origin.x + imageSpacerWidth),
        round((bounds.size.height - titleSize.height - subtitleSize.height) / 2),
        subtitleSize.width,
        subtitleSize.height);

    self.imageView.frame = imageRect;
    self.titleView.frame = titleRect;
    self.subtitleView.frame = subtitleRect;
}
@end
