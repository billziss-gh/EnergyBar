/**
 * @file DockWidget.m
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

#import "DockWidget.h"

@interface DockWidgetApplication : NSObject <NSCopying>
@property (retain) NSString *name;
@property (retain) NSString *path;
@property (retain) NSImage *icon;
@property (assign) BOOL running;
@end

@implementation DockWidgetApplication
- (void)dealloc
{
    self.name = nil;
    self.path = nil;
    self.icon = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    DockWidgetApplication *copy = [[DockWidgetApplication alloc] init];
    copy.name = self.name;
    copy.path = self.path;
    copy.icon = self.icon;
    copy.running = self.running;
    return copy;
}
@end

@interface DockWidgetItemView : NSScrubberItemView
@property (retain) NSImageView *appIconView;
@property (retain) NSImageView *appRunningView;
@property (retain, getter=getAppIcon, setter=setAppIcon:) NSImage *appIcon;
@property (assign, getter=isAppRunning, setter=setAppRunning:) BOOL appRunning;
@end

@implementation DockWidgetItemView
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (nil == self)
        return nil;

    self.appIconView = [NSImageView imageViewWithImage:[NSImage imageNamed:NSImageNameApplicationIcon]];
    self.appIconView.imageScaling = NSImageScaleProportionallyDown;

    self.appRunningView = [NSImageView imageViewWithImage:[NSImage imageNamed:@"DockDot"]];
    self.appRunningView.imageScaling = NSImageScaleProportionallyDown;
    self.appRunningView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.appRunningView.hidden = YES;

    [self addSubview:self.appIconView];
    [self addSubview:self.appRunningView];

    return self;
}

- (void)dealloc
{
    self.appIconView = nil;
    self.appRunningView = nil;

    [super dealloc];
}

- (NSImage *)getAppIcon
{
    return self.appIconView.image;
}

- (void)setAppIcon:(NSImage *)value
{
    if (nil == value)
        value = [NSImage imageNamed:NSImageNameApplicationIcon];
    self.appIconView.image = value;
}

- (BOOL)isAppRunning
{
    return !self.appRunningView.hidden;
}

- (void)setAppRunning:(BOOL)value
{
    self.appRunningView.hidden = !value;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
    NSRect iconRect = self.bounds;
    if (iconRect.size.height >= 4)
    {
        iconRect.origin.y += 4;
        iconRect.size.height -= 4;
    }
    self.appIconView.frame = iconRect;

    [super resizeSubviewsWithOldSize:oldSize];
}
@end

@interface DockWidget () <NSScrubberDataSource, NSScrubberFlowLayoutDelegate>
@property (retain) DockWidgetApplication *separator;
@property (retain) NSArray *defaultApps;
@property (retain) NSArray *runningApps;
@end

static NSString *dockItemIdentifier = @"dockItem";

static NSSize dockItemSize = { 50, 30 };
static NSSize dockSeparatorSize = { 10, 30 };

@implementation DockWidget
- (void)commonInit
{
    self.separator = [[[DockWidgetApplication alloc] init] autorelease];

    self.customizationLabel = @"Dock";
    NSScrubberFlowLayout *layout = [[[NSScrubberFlowLayout alloc] init] autorelease];
    NSScrubber *scrubber = [[[NSScrubber alloc] initWithFrame:NSMakeRect(0, 0, 200, 30)] autorelease];
    [scrubber registerClass:[DockWidgetItemView class] forItemIdentifier:dockItemIdentifier];
    scrubber.dataSource = self;
    scrubber.delegate = self;
    scrubber.showsAdditionalContentIndicators = YES;
    scrubber.mode = NSScrubberModeFree;
    scrubber.continuous = NO;
    scrubber.itemAlignment = NSScrubberAlignmentNone;
    scrubber.scrubberLayout = layout;
    self.view = scrubber;

    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(didLaunchApplication:)
        name:NSWorkspaceDidLaunchApplicationNotification
        object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(didTerminateApplication:)
        name:NSWorkspaceDidTerminateApplicationNotification
        object:nil];
}

- (void)dealloc
{
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        removeObserver:self];

    self.separator = nil;
    self.defaultApps = nil;
    self.runningApps = nil;
    [super dealloc];
}

- (NSInteger)numberOfItemsForScrubber:(NSScrubber *)scrubber
{
    return self.apps.count;
}

- (NSScrubberItemView *)scrubber:(NSScrubber *)scrubber viewForItemAtIndex:(NSInteger)index
{
    DockWidgetItemView *view = [scrubber makeItemWithIdentifier:dockItemIdentifier owner:nil];
    DockWidgetApplication *app = [self.apps objectAtIndex:index];
    if (nil != app.path)
    {
        view.appIcon = app.icon;
        view.appRunning = app.running;
    }
    else
    {
        view.appIcon = [NSImage imageNamed:NSImageNameTouchBarPlayheadTemplate];
        view.appRunning = NO;
    }
    return view;
}

- (NSSize)scrubber:(NSScrubber *)scrubber
    layout:(NSScrubberFlowLayout *)layout
    sizeForItemAtIndex:(NSInteger)index
{
    DockWidgetApplication *app = [self.apps objectAtIndex:index];
    if (nil != app.path)
        return dockItemSize;
    else
        return dockSeparatorSize;
}

- (void)scrubber:(NSScrubber *)scrubber
    didSelectItemAtIndex:(NSInteger)index
{
    DockWidgetApplication *app = [self.apps objectAtIndex:index];
    if (nil != app.path)
        [[NSWorkspace sharedWorkspace] launchApplication:app.path];
}

- (void)didLaunchApplication:(NSNotification *)notification
{
    [self reset];
}

- (void)didTerminateApplication:(NSNotification *)notification
{
    [self reset];
}

- (NSArray *)apps
{
    if (nil == self.defaultApps)
    {
        self.runningApps = nil;

        NSArray *defaultApps = [[NSUserDefaults standardUserDefaults] arrayForKey:@"defaultApps"];
        NSMutableArray *newDefaultApps = [NSMutableArray array];
        for (NSDictionary *a in defaultApps)
        {
            DockWidgetApplication *app = [[[DockWidgetApplication alloc] init] autorelease];
            app.name = [a objectForKey:@"NSApplicationName"];
            app.path = [a objectForKey:@"NSApplicationPath"];
            app.icon = [[NSWorkspace sharedWorkspace] iconForFile:app.path];
            [newDefaultApps addObject:app];
        }
        self.defaultApps = [[newDefaultApps copy] autorelease];
    }

    if (nil == self.runningApps)
    {
        NSMutableDictionary *defaultAppsDict = [NSMutableDictionary dictionary];
        for (DockWidgetApplication *app in self.defaultApps)
        {
            app.running = NO;
            [defaultAppsDict setObject:app forKey:app.path];
        }

        NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
        NSMutableArray *newRunningApps = [NSMutableArray array];
        for (NSRunningApplication *a in runningApps)
        {
            if (NSApplicationActivationPolicyRegular != a.activationPolicy)
                continue;

            DockWidgetApplication *app;
            NSString *path = a.bundleURL.path;
            if (nil != (app = [defaultAppsDict objectForKey:path]))
            {
                app.running = YES;
                continue;
            }

            app = [[[DockWidgetApplication alloc] init] autorelease];
            app.name = a.localizedName;
            app.path = a.bundleURL.path;
            app.icon = a.icon;
            app.running = YES;
            [newRunningApps addObject:app];
        }
        self.runningApps = [[newRunningApps copy] autorelease];
    }

#if 0
    if (0 < self.defaultApps.count && 0 < self.runningApps.count)
        return [[self.defaultApps arrayByAddingObject:self.separator]
            arrayByAddingObjectsFromArray:self.runningApps];
    else if (0 < self.defaultApps.count)
        return self.defaultApps;
    else
        return self.runningApps;
#else
    return [self.defaultApps arrayByAddingObjectsFromArray:self.runningApps];
#endif
}

- (void)reset
{
    NSArray *oldApps = [[[NSArray alloc] initWithArray:self.apps copyItems:YES] autorelease];
    self.runningApps = nil;
    NSArray *newApps = self.apps;

    NSMutableDictionary *oldAppsDict = [NSMutableDictionary dictionary];
    for (DockWidgetApplication *oldApp in oldApps)
        [oldAppsDict setObject:oldApp forKey:oldApp.path];

    NSMutableDictionary *newAppsDict = [NSMutableDictionary dictionary];
    for (DockWidgetApplication *newApp in newApps)
        [newAppsDict setObject:newApp forKey:newApp.path];

    NSScrubber *scrubber = self.view;
    [scrubber performSequentialBatchUpdates:^(void)
    {
        NSUInteger count = oldApps.count;

        for (NSUInteger i = oldApps.count - 1; oldApps.count > i; i--)
        {
            DockWidgetApplication *oldApp = [oldApps objectAtIndex:i];
            DockWidgetApplication *newApp = [newAppsDict objectForKey:oldApp.path];

            if (nil == newApp)
            {
                [scrubber removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:i]];
                count--;
            }
        }

        for (NSUInteger i = 0; newApps.count > i; i++)
        {
            DockWidgetApplication *newApp = [newApps objectAtIndex:i];
            DockWidgetApplication *oldApp = [oldAppsDict objectForKey:newApp.path];

            if (nil == oldApp)
            {
                [scrubber insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:count]];
                count++;
            }
        }

        for (NSUInteger i = 0; oldApps.count > i; i++)
        {
            DockWidgetApplication *oldApp = [oldApps objectAtIndex:i];
            DockWidgetApplication *newApp = [newAppsDict objectForKey:oldApp.path];

            if (nil != newApp && [oldApp.path isEqualToString:newApp.path])
            {
                if (![oldApp.name isEqualToString:newApp.name] || oldApp.icon != newApp.icon ||
                    oldApp.running != newApp.running)
                    [scrubber reloadItemsAtIndexes:[NSIndexSet indexSetWithIndex:i]];
            }
        }
    }];
}
@end
