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
    self.imagePosition = NSImageLeft;

    self.titleFont = [NSFont
        systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]];
    self.titleLineBreakMode = NSLineBreakByTruncatingTail;

    return self;
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(200, 30);
}
@end

@implementation NowPlayingWidget
{
    BOOL _showsArtist;
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

    NSString *title = nil;
    if (!_showsArtist)
    {
        title = [NowPlaying sharedInstance].title;
        if (nil != title)
            title = [@"♫ " stringByAppendingString:title];
    }
    else
    {
        title = [NowPlaying sharedInstance].artist;
        if (nil != title)
            title = [@"☻ " stringByAppendingString:title];
    }

    if (nil == icon && nil == title)
        title = @"♫";

    NowPlayingWidgetView *view = self.view;
    view.image = icon;
    view.title = title;
}

- (void)nowPlayingNotification:(NSNotification *)notification
{
    [self resetNowPlaying];
}

- (void)clickAction:(NSGestureRecognizer *)recognizer
{
    if (NSGestureRecognizerStateRecognized != recognizer.state)
        return;

    _showsArtist = !_showsArtist;
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
