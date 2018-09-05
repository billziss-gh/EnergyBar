/**
 * @file NowPlayingWidget.m
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

#import "NowPlayingWidget.h"
#import "ImageTitleView.h"
#import "NowPlaying.h"

@interface NowPlayingWidgetView : ImageTitleView
@end

@implementation NowPlayingWidgetView
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (nil == self)
        return nil;

    self.wantsLayer = YES;
    self.layer.cornerRadius = 8.0;
    self.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];

    self.imageSize = NSMakeSize(20, 20);

    self.titleFont = [NSFont
        systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]];
    self.titleLineBreakMode = NSLineBreakByTruncatingTail;
    
    self.subtitleFont = [NSFont systemFontOfSize:
                         [NSFont systemFontSizeForControlSize:NSControlSizeSmall]];
    self.subtitleLineBreakMode = NSLineBreakByTruncatingTail;

    self.layoutOptions = ImageTitleViewLayoutOptionImage | ImageTitleViewLayoutOptionTitle;
    
    return self;
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(200, 30);
}
@end

@implementation NowPlayingWidget
{
    NowPlayingWidgetDisplayOptions _displayOptions;
}

- (void)commonInit
{
    self.customizationLabel = @"Now Playing";
    NSClickGestureRecognizer *clickRecognizer = [[[NSClickGestureRecognizer alloc]
        initWithTarget:self action:@selector(clickAction:)] autorelease];
    clickRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    NSPressGestureRecognizer *pressRecognizer = [[[NSPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(pressAction:)] autorelease];
    pressRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    pressRecognizer.minimumPressDuration = LongPressDuration;
    self.view = [[[NowPlayingWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    [self.view addGestureRecognizer:clickRecognizer];
    [self.view addGestureRecognizer:pressRecognizer];
    
    _displayOptions = NowPlayingWidgetDisplayOptionTitle;

    [self resetNowPlaying];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(nowPlayingNotification:)
        name:NowPlayingInfoNotification
        object:nil];

    [NowPlaying sharedInstance];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];

    [super dealloc];
}

- (void)resetNowPlaying
{
    NSImage *icon = [NowPlaying sharedInstance].appIcon;
    NSString *title = [NowPlaying sharedInstance].title;
    NSString *subtitle = [NowPlaying sharedInstance].artist;
    
    if (nil != title)
        title = [@"♫ " stringByAppendingString:title];
    
    if (nil == icon && nil == title)
        title = @"♫";
    
    if (nil != subtitle)
        subtitle = [@"☻ " stringByAppendingString:subtitle];
    
    ImageTitleViewLayoutOptions layoutOptions = ImageTitleViewLayoutOptionImage;
    
    if (_displayOptions & NowPlayingWidgetDisplayOptionArtist) {
        layoutOptions = layoutOptions | ImageTitleViewLayoutOptionTitle;
    }
    
    if (_displayOptions & NowPlayingWidgetDisplayOptionTitle) {
        layoutOptions = layoutOptions | ImageTitleViewLayoutOptionSubtitle;
    }

    NowPlayingWidgetView *view = self.view;
    view.image = icon;
    view.title = title;
    view.subtitle = subtitle;
    view.layoutOptions = layoutOptions;
}

- (void)nowPlayingNotification:(NSNotification *)notification
{
    [self resetNowPlaying];
}

- (void)clickAction:(NSGestureRecognizer *)recognizer
{
    if (NSGestureRecognizerStateRecognized != recognizer.state)
        return;
    
    // Cycle the display options
    if (_displayOptions & NowPlayingWidgetDisplayOptionArtist && _displayOptions & NowPlayingWidgetDisplayOptionTitle) {
        _displayOptions = NowPlayingWidgetDisplayOptionArtist;
    } else if (_displayOptions & NowPlayingWidgetDisplayOptionArtist) {
        _displayOptions = NowPlayingWidgetDisplayOptionTitle;
    } else {
        _displayOptions = NowPlayingWidgetDisplayOptionArtist | NowPlayingWidgetDisplayOptionTitle;
    }
    
    [self resetNowPlaying];
}

- (void)pressAction:(NSGestureRecognizer *)recognizer
{
    if (NSGestureRecognizerStateBegan != recognizer.state)
        return;

    NSString *appBundleIdentifier = [NowPlaying sharedInstance].appBundleIdentifier;
    if (nil != appBundleIdentifier)
    {
        [[NSWorkspace sharedWorkspace]
            launchAppWithBundleIdentifier:appBundleIdentifier
            options:0
            additionalEventParamDescriptor:nil
            launchIdentifier:nil];
    }
}
@end
