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
    NSSize titleSize = [self.titleView intrinsicContentSize];
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
        bounds.size.width - (iconSize.width + spacerWidth),
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
- (void)commonInit
{
    self.customizationLabel = @"Now Playing";
    NSPressGestureRecognizer *recognizer = [[[NSPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(pressAction:)] autorelease];
    recognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    recognizer.minimumPressDuration = 1.0;
    self.view = [[[NowPlayingWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    [self.view addGestureRecognizer:recognizer];

    [NowPlaying sharedInstance];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(nowPlayingNotification:)
        name:@"NowPlaying"
        object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];

    [super dealloc];
}

- (void)nowPlayingNotification:(NSNotification *)notification
{
    NowPlayingWidgetView *view = self.view;
    view.icon = [NowPlaying sharedInstance].appIcon;
    view.title = [NowPlaying sharedInstance].title;
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
