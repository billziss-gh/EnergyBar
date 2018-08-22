/**
 * @file NowPlayingWidget.m
 *
 * @copyright 2018 Bill Zissimopoulos
 */
/*
 * This file is part of TouchBarDock.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import "NowPlayingWidget.h"
#import "NowPlaying.h"

@interface NowPlayingWidgetIconView : NSImageView
@end

@implementation NowPlayingWidgetIconView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(30, NSViewNoIntrinsicMetric);
}
@end

@interface NowPlayingWidgetTitleView : NSTextField
@end

@implementation NowPlayingWidgetTitleView
- (NSSize)intrinsicContentSize
{
    NSSize size = [super intrinsicContentSize];
    size.width = MIN(size.width, 150);
    return size;
}
@end

@interface NowPlayingWidgetView : NSView
@end

@implementation NowPlayingWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(200, NSViewNoIntrinsicMetric);
}
@end

@implementation NowPlayingWidget
- (void)commonInit
{
    self.customizationLabel = @"Now Playing";

    NSImageView *iconView = [[[NowPlayingWidgetIconView alloc]
        initWithFrame:NSZeroRect] autorelease];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.imageScaling = NSImageScaleProportionallyDown;
    iconView.tag = 'icon';

    NSTextField *titleView = [NowPlayingWidgetTitleView labelWithString:@""];
    titleView.translatesAutoresizingMaskIntoConstraints = NO;
    titleView.font = [NSFont systemFontOfSize:[NSFont
        systemFontSizeForControlSize:NSControlSizeSmall]];
    titleView.lineBreakMode = NSLineBreakByTruncatingTail;
    titleView.alignment = NSTextAlignmentLeft;
    titleView.tag = 'name';

    NSView *view = [[[NowPlayingWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    [view addSubview:iconView];
    [view addSubview:titleView];

    NSDictionary *views = NSDictionaryOfVariableBindings(iconView, titleView);
    NSArray *constraints;
    constraints = [NSLayoutConstraint
        constraintsWithVisualFormat:@"V:|[iconView]|"
        options:0
        metrics:nil
        views:views];
    [view addConstraints:constraints];
    constraints = [NSLayoutConstraint
        constraintsWithVisualFormat:@"V:|[titleView]|"
        options:0
        metrics:nil
        views:views];
    [view addConstraints:constraints];
    constraints = [NSLayoutConstraint
        constraintsWithVisualFormat:@"|[iconView(==30)][titleView(<=150)]|"
        options:0
        metrics:nil
        views:views];
    [view addConstraints:constraints];

    self.view = view;

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
    NSImage *appIcon = [NowPlaying sharedInstance].appIcon;
    NSString *title = [NowPlaying sharedInstance].title;

    if (nil == title)
        title = @"";

    [[self.view viewWithTag:'icon'] setImage:appIcon];
    [[self.view viewWithTag:'name'] setStringValue:title];
}
@end
