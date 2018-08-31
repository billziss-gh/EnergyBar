/**
 * @file ImageTitleView.h
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

#import <Cocoa/Cocoa.h>

@interface ImageTitleView : NSView
@property (retain, getter=image, setter=setImage:) NSImage *image;
@property (assign, getter=imageSize, setter=setImageSize:) NSSize imageSize;
@property (assign, getter=imagePosition, setter=setImagePosition:) NSCellImagePosition imagePosition;
    // supported: NSNoImage, NSImageOnly, NSImageLeft
@property (retain, getter=title, setter=setTitle:) NSString *title;
@property (retain, getter=titleFont, setter=setTitleFont:) NSFont *titleFont;
@property (assign, getter=titleLineBreakMode, setter=setTitleLineBreakMode:) NSLineBreakMode titleLineBreakMode;
@end
