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

@interface NowPlayingWidgetButton : NSButton
@end

@implementation NowPlayingWidgetButton
- (NSSize)intrinsicContentSize
{
    NSSize size = [super intrinsicContentSize];
    size.width = MAX(size.width, 150);
    return size;
}
@end

@implementation NowPlayingWidget
- (void)commonInit
{
    self.customizationLabel = @"Now Playing";

    NSButton *button = [NowPlayingWidgetButton
        buttonWithTitle:@"Now Playing" target:self action:@selector(click:)];
    button.font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
    button.imageHugsTitle = YES;
    button.bordered = YES;
    button.imagePosition = NSImageLeft;
    self.view = button;

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
    NSButton *button = self.view;
    button.title = [NowPlaying sharedInstance].title;
    button.image = [NowPlaying sharedInstance].appIcon;
}

- (void)click:(id)sender
{
}
@end
