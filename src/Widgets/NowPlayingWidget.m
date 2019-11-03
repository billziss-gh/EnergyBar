/**
 * @file NowPlayingWidget.m
 *
 * @copyright 2018-2019 Bill Zissimopoulos
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
#import "TodoWidget.h"

@interface NowPlayingWidgetView : ImageTitleView
@property (assign) BOOL showsSmallWidget;
@end

@implementation NowPlayingWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(self.showsSmallWidget ? 130 : 180, NSViewNoIntrinsicMetric);
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

- (BOOL)showsSmallWidget
{
    NowPlayingWidgetView *imageTitleView = self.view;
    return imageTitleView.showsSmallWidget;
}

- (void)setShowsSmallWidget:(BOOL)value
{
    NowPlayingWidgetView *imageTitleView = self.view;
    imageTitleView.showsSmallWidget = value;

    if (!value)
    {
        imageTitleView.imageSize = NSMakeSize(26, 26);
        imageTitleView.titleFont = [NSFont boldSystemFontOfSize:[NSFont
            systemFontSizeForControlSize:NSControlSizeSmall]];
        imageTitleView.subtitleFont = [NSFont systemFontOfSize:[NSFont
            systemFontSizeForControlSize:NSControlSizeSmall]];
    }
    else
    {
        imageTitleView.imageSize = NSMakeSize(16, 16);
        imageTitleView.titleFont = [NSFont boldSystemFontOfSize:[NSFont
            systemFontSizeForControlSize:NSControlSizeMini]];
        imageTitleView.subtitleFont = [NSFont systemFontOfSize:[NSFont
            systemFontSizeForControlSize:NSControlSizeMini]];
    }
}
@end

@implementation NowPlayingWidget
{
    BOOL _showsActiveAppOnTap;
    BOOL _showsTodoOnTap;
    double _todoShowsEventsInterval;
    BOOL _todoShowsReminders;
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

- (BOOL)showsTodoOnTap
{
    return _showsTodoOnTap;
}

- (void)setShowsTodoOnTap:(BOOL)value
{
    if (_showsTodoOnTap == value)
        return;

    _showsTodoOnTap = value;
    if (_showsTodoOnTap)
    {
        TodoWidget *todo = [[[TodoWidget alloc] initWithIdentifier:@"_Todo"] autorelease];
        todo.showsEventsInterval = _todoShowsEventsInterval;
        todo.showsReminders = _todoShowsReminders;
        [self addWidget:todo];
    }
    else
        [self removeWidgetWithIdentifier:@"_Todo"];
}

- (BOOL)showsSmallWidget
{
    return [(id)[self.widgets objectAtIndex:0] showsSmallWidget];
}

- (void)setShowsSmallWidget:(BOOL)value
{
    [(id)[self.widgets objectAtIndex:0] setShowsSmallWidget:value];
    [self.view invalidateIntrinsicContentSize];
}

- (double)todoShowsEventsInterval
{
    return _todoShowsEventsInterval;
}

- (void)todoSetShowsEventsInterval:(double)value
{
    _todoShowsEventsInterval = value;

    TodoWidget *todo = (id)[self widgetWithIdentifier:@"_Todo"];
    todo.showsEventsInterval = value;
}

- (BOOL)todoShowsReminders
{
    return _todoShowsReminders;
}

- (void)todoSetShowsReminders:(BOOL)value
{
    _todoShowsReminders = value;

    TodoWidget *todo = (id)[self widgetWithIdentifier:@"_Todo"];
    todo.showsReminders = value;
}

- (void)todoReset
{
    TodoWidget *todo = (id)[self widgetWithIdentifier:@"_Todo"];
    [todo reset];
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
