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
#import "FixedSizeLabel.h"
#import "ImageTitleView.h"
#import "NowPlaying.h"

@interface NowPlayingWidgetView : NSView
@property (retain) ImageTitleView *imageTitleView;
@property (retain) FixedSizeLabel *fixedSizeLabel;
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

    self.imageTitleView = [[[ImageTitleView alloc] initWithFrame:NSZeroRect] autorelease];
    self.imageTitleView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.imageTitleView.imageSize = NSMakeSize(26, 26);
    self.imageTitleView.titleFont = [NSFont boldSystemFontOfSize:[NSFont
        systemFontSizeForControlSize:NSControlSizeSmall]];
    self.imageTitleView.titleLineBreakMode = NSLineBreakByTruncatingTail;
    self.imageTitleView.subtitleFont = [NSFont systemFontOfSize:[NSFont
        systemFontSizeForControlSize:NSControlSizeSmall]];
    self.imageTitleView.subtitleLineBreakMode = NSLineBreakByTruncatingTail;

    self.fixedSizeLabel = [FixedSizeLabel labelWithString:@""];
    self.fixedSizeLabel.frame = NSZeroRect;
    self.fixedSizeLabel.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.fixedSizeLabel.alignment = NSTextAlignmentCenter;
    self.fixedSizeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.fixedSizeLabel.fixedSize = [self intrinsicContentSize];
    self.fixedSizeLabel.hidden = YES;

    [self addSubview:self.imageTitleView];
    [self addSubview:self.fixedSizeLabel];

    return self;
}

- (void)dealloc
{
    self.imageTitleView = nil;
    self.fixedSizeLabel = nil;

    [super dealloc];
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(200, NSViewNoIntrinsicMetric);
}
@end

@implementation NowPlayingWidget
{
    BOOL _showsActiveAppOnTap;
    BOOL _showsActiveApp;
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
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter]
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
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(didActivateApplication:)
        name:NSWorkspaceDidActivateApplicationNotification
        object:nil];

    [self resetNowPlaying];
    [self resetActiveApp];
}

- (void)viewDidDisappear
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        removeObserver:self];
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
    if (!_showsActiveAppOnTap)
        _showsActiveApp = NO;
    [self updateVisibleView];
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
    view.imageTitleView.image = icon;
    view.imageTitleView.title = title;
    view.imageTitleView.subtitle = subtitle;
    view.imageTitleView.layoutOptions = layoutOptions;
}

- (void)resetActiveApp
{
    NSRunningApplication *app = [[NSWorkspace sharedWorkspace] menuBarOwningApplication];
    if (nil != app)
    {
        NowPlayingWidgetView *view = self.view;
        view.fixedSizeLabel.stringValue = app.localizedName;
    }
}

- (void)updateVisibleView
{
    NowPlayingWidgetView *view = self.view;
    view.imageTitleView.hidden = _showsActiveApp;
    view.fixedSizeLabel.hidden = !_showsActiveApp;
}

- (void)didActivateApplication:(NSNotification *)notification
{
    [self resetActiveApp];
}

- (void)nowPlayingNotification:(NSNotification *)notification
{
    [self resetNowPlaying];
}

- (void)clickAction:(NSGestureRecognizer *)recognizer
{
    if (NSGestureRecognizerStateRecognized != recognizer.state)
        return;

    if (!_showsActiveAppOnTap)
        return;

    _showsActiveApp = !_showsActiveApp;
    [self updateVisibleView];
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
