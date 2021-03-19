/**
 * @file ImageTitleView.h
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

typedef NS_OPTIONS(NSInteger, ImageTitleViewLayoutOptions)
{
    ImageTitleViewLayoutOptionImage     = 1 << 0,
    ImageTitleViewLayoutOptionTitle     = 1 << 1,
    ImageTitleViewLayoutOptionSubtitle  = 1 << 2,
};

@interface ImageTitleView : NSView
@property (retain, getter=image, setter=setImage:) NSImage *image;
@property (assign, getter=imageSize, setter=setImageSize:) NSSize imageSize;
@property (retain, getter=title, setter=setTitle:) NSString *title;
@property (retain, getter=titleFont, setter=setTitleFont:) NSFont *titleFont;
@property (retain, getter=titleColor, setter=setTitleColor:) NSColor *titleColor;
@property (assign, getter=titleLineBreakMode, setter=setTitleLineBreakMode:)
    NSLineBreakMode titleLineBreakMode;
@property (retain, getter=subtitle, setter=setSubtitle:) NSString *subtitle;
@property (retain, getter=subtitleFont, setter=setSubtitleFont:) NSFont *subtitleFont;
@property (retain, getter=subtitleColor, setter=setSubtitleColor:) NSColor *subtitleColor;
@property (assign, getter=subtitleLineBreakMode, setter=setSubtitleLineBreakMode:)
    NSLineBreakMode subtitleLineBreakMode;
@property (assign, getter=layoutOptions, setter=setLayoutOptions:)
    ImageTitleViewLayoutOptions layoutOptions;
@end

@interface LeftImageTitleView : NSView
@property (retain, getter=image, setter=setImage:) NSImage *image;
@property (assign, getter=imageSize, setter=setImageSize:) NSSize imageSize;
@property (retain, getter=title, setter=setTitle:) NSString *title;
@property (retain, getter=titleFont, setter=setTitleFont:) NSFont *titleFont;
@property (retain, getter=titleColor, setter=setTitleColor:) NSColor *titleColor;
@property (assign, getter=titleLineBreakMode, setter=setTitleLineBreakMode:)
    NSLineBreakMode titleLineBreakMode;
@property (retain, getter=subtitle, setter=setSubtitle:) NSString *subtitle;
@property (retain, getter=subtitleFont, setter=setSubtitleFont:) NSFont *subtitleFont;
@property (retain, getter=subtitleColor, setter=setSubtitleColor:) NSColor *subtitleColor;
@property (assign, getter=subtitleLineBreakMode, setter=setSubtitleLineBreakMode:)
    NSLineBreakMode subtitleLineBreakMode;
@property (assign, getter=layoutOptions, setter=setLayoutOptions:)
    ImageTitleViewLayoutOptions layoutOptions;
@end

@interface RightImageTitleView : NSView
@property (retain, getter=image, setter=setImage:) NSImage *image;
@property (assign, getter=imageSize, setter=setImageSize:) NSSize imageSize;
@property (retain, getter=title, setter=setTitle:) NSString *title;
@property (retain, getter=titleFont, setter=setTitleFont:) NSFont *titleFont;
@property (retain, getter=titleColor, setter=setTitleColor:) NSColor *titleColor;
@property (assign, getter=titleLineBreakMode, setter=setTitleLineBreakMode:)
    NSLineBreakMode titleLineBreakMode;
@property (retain, getter=subtitle, setter=setSubtitle:) NSString *subtitle;
@property (retain, getter=subtitleFont, setter=setSubtitleFont:) NSFont *subtitleFont;
@property (retain, getter=subtitleColor, setter=setSubtitleColor:) NSColor *subtitleColor;
@property (assign, getter=subtitleLineBreakMode, setter=setSubtitleLineBreakMode:)
    NSLineBreakMode subtitleLineBreakMode;
@property (assign, getter=layoutOptions, setter=setLayoutOptions:)
    ImageTitleViewLayoutOptions layoutOptions;
@end
