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
#import "ActiveAppWidget.h"
#import "ImageTitleView.h"
#import "NowPlaying.h"

@interface NowPlayingWidgetView : ImageTitleView
@end

@implementation NowPlayingWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(180, NSViewNoIntrinsicMetric);
}
@end

@interface NowPlayingInternalWidget : CustomWidget
@end

@implementation NowPlayingInternalWidget
- (void)commonInit
{
    self.customizationLabel = @"Now Playing";

    ImageTitleView *imageTitleView = [[[NowPlayingWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    imageTitleView.wantsLayer = YES;
    imageTitleView.layer.cornerRadius = 8.0;
    imageTitleView.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];
    imageTitleView.imageSize = NSMakeSize(26, 26);
    imageTitleView.titleFont = [NSFont boldSystemFontOfSize:[NSFont
        systemFontSizeForControlSize:NSControlSizeSmall]];
    imageTitleView.titleLineBreakMode = NSLineBreakByTruncatingTail;
    imageTitleView.subtitleFont = [NSFont systemFontOfSize:[NSFont
        systemFontSizeForControlSize:NSControlSizeSmall]];
    imageTitleView.subtitleLineBreakMode = NSLineBreakByTruncatingTail;
    imageTitleView.layoutOptions = ImageTitleViewLayoutOptionTitle;
    imageTitleView.title = @"♫";
    self.view = imageTitleView;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];

    [super dealloc];
}

- (void)viewWillAppear
{
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(nowPlayingNotification:)
        name:NowPlayingInfoNotification
        object:nil];

    [self resetNowPlaying];
}

- (void)viewDidDisappear
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];
}

- (void)resetNowPlaying
{
    NSImage *icon = [NowPlaying sharedInstance].appIcon;
    NSString *title = [NowPlaying sharedInstance].title;
    NSString *subtitle = [NowPlaying sharedInstance].artist;

    if (nil == icon && nil == title && nil == subtitle)
        title = @"♫";

    ImageTitleViewLayoutOptions layoutOptions = 0;
    if (nil != icon)
        layoutOptions = layoutOptions | ImageTitleViewLayoutOptionImage;
    if (nil != title)
        layoutOptions = layoutOptions | ImageTitleViewLayoutOptionTitle;
    if (nil != subtitle)
        layoutOptions = layoutOptions | ImageTitleViewLayoutOptionSubtitle;

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
@end

@implementation NowPlayingWidget
{
    BOOL _showsActiveAppOnTap;
}

- (void)commonInit
{
    [self addWidget:[[[NowPlayingInternalWidget alloc]
        initWithIdentifier:@"_NowPlayingInternal"] autorelease]];
}

- (BOOL)showsActiveAppOnTap
{
    return _showsActiveAppOnTap;
}

- (void)setShowsActiveAppOnTap:(BOOL)value
{
    if (_showsActiveAppOnTap == value)
        return;

    _showsActiveAppOnTap = value;
    if (_showsActiveAppOnTap)
        [self addWidget:[[[ActiveAppWidget alloc]
            initWithIdentifier:@"_ActiveApp"] autorelease]];
    else
        [self removeWidgetWithIdentifier:@"_ActiveApp"];
}

- (void)longPressAction:(id)sender
{
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
