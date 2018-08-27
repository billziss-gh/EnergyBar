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
#import "NowPlaying.h"

static NSSize iconSize = { 20, 20 };
static CGFloat spacerWidth = 4;

@interface NowPlayingWidgetView : NSScrubberItemView <NSAnimationDelegate>
@property (retain) NSImageView *iconView;
@property (retain) NSTextField *titleView;
@end

@implementation NowPlayingWidgetView
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (nil == self)
        return nil;

    self.iconView = [[[NSImageView alloc] initWithFrame:NSZeroRect] autorelease];
    self.iconView.autoresizingMask = 0;
    self.iconView.imageScaling = NSImageScaleProportionallyDown;

    self.titleView = [NSTextField labelWithString:@""];
    self.titleView.wantsLayer = YES;
    self.titleView.layer.cornerRadius = 4.0;
    self.titleView.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];
    self.titleView.autoresizingMask = 0;
    self.titleView.font = [NSFont systemFontOfSize:[NSFont
        systemFontSizeForControlSize:NSControlSizeSmall]];
    self.titleView.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleView.alignment = NSTextAlignmentLeft;

    [self addSubview:self.iconView];
    [self addSubview:self.titleView];

    return self;
}

- (void)dealloc
{
    self.iconView = nil;
    self.titleView = nil;

    [super dealloc];
}

- (NSImage *)getIcon
{
    return self.iconView.image;
}

- (void)setIcon:(NSImage *)value
{
    self.iconView.image = value;
}

- (NSString *)getTitle
{
    return self.titleView.stringValue;
}

- (void)setTitle:(NSString *)value
{
    if (nil == value)
        value = @"";
    self.titleView.stringValue = value;
    self.needsLayout = YES;
}

- (void)layout
{
    [super layout];

    NSRect bounds = self.bounds;
    NSSize titleSize = [self.titleView.cell cellSizeForBounds:bounds];
    if (titleSize.width > bounds.size.width - (iconSize.width + spacerWidth))
        titleSize.width = bounds.size.width - (iconSize.width + spacerWidth);
    CGFloat totalWidth = iconSize.width + spacerWidth + titleSize.width;
    NSRect iconRect = NSMakeRect(
        (bounds.size.width - totalWidth) / 2,
        (bounds.size.height - iconSize.height) / 2,
        iconSize.width,
        iconSize.height);
    NSRect titleRect = NSMakeRect(
        iconRect.origin.x + iconSize.width + spacerWidth,
        (bounds.size.height - titleSize.height) / 2,
        titleSize.width,
        titleSize.height);

    self.iconView.frame = iconRect;
    self.titleView.frame = titleRect;
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
    pressRecognizer.minimumPressDuration = 1.0;
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
    view.icon = icon;
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
