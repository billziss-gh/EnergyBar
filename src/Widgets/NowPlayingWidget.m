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
#import "FixedSizeLabel.h"
#import "NowPlaying.h"

@implementation NowPlayingWidget
- (void)commonInit
{
    self.customizationLabel = @"Now Playing";

    NSImageView *appIconView = [[[NSImageView alloc] initWithFrame:NSZeroRect] autorelease];
    appIconView.tag = 'icon';
    appIconView.translatesAutoresizingMaskIntoConstraints = NO;

    FixedSizeLabel *titleLabel = [FixedSizeLabel labelWithString:@""];
    titleLabel.tag = 'name';
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.alignment = NSTextAlignmentCenter;

    NSView *view = [[[NSView alloc] initWithFrame:NSZeroRect] autorelease];
    [view addSubview:appIconView];
    [view addSubview:titleLabel];

    NSDictionary *views = NSDictionaryOfVariableBindings(appIconView, titleLabel);
    NSArray *constraints = [NSLayoutConstraint
        constraintsWithVisualFormat:@"|[appIconView][titleLabel]|"
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

- (void)click:(id)sender
{
}
@end
