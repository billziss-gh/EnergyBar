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

static NSString *dockItemIdentifier = @"dockItem";
static NSSize dockItemSize = { 50, 30 };
static CGFloat dockItemBounce = 10;

@interface DockWidgetApplication : NSObject <NSCopying>
@property (retain) NSString *name;
@property (retain) NSString *path;
@property (retain) NSImage *icon;
@property (assign) BOOL isDefault;
@property (assign) pid_t pid;
@property (assign) BOOL launching;
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
    copy.isDefault = self.isDefault;
    copy.pid = self.pid;
    copy.launching = self.launching;
    return copy;
}
@end

@interface DockWidgetBounceAnimation : NSAnimation
@property (assign) NSView *view;
@end

@implementation DockWidgetBounceAnimation
- (void)setCurrentProgress:(NSAnimationProgress)progress
{
    /* use current time to compute progress for our animations! */
    progress = 2 * fmod(CFAbsoluteTimeGetCurrent(), 0.5);

    [super setCurrentProgress:progress];

    if (0.5 > progress)
        [self.view setFrameOrigin:NSMakePoint(0, dockItemBounce * 2 * progress)];
    else
        [self.view setFrameOrigin:NSMakePoint(0, dockItemBounce * 2 * (1 - progress))];
}
@end

@interface DockWidgetItemView : NSScrubberItemView <NSAnimationDelegate>
@property (retain) NSView *appIconContainerView;
@property (retain) NSImageView *appIconView;
@property (retain) NSImageView *appRunningView;
@property (retain) DockWidgetBounceAnimation *bounceAnimation;
@property (retain, getter=getAppIcon, setter=setAppIcon:) NSImage *appIcon;
@property (assign, getter=isAppRunning, setter=setAppRunning:) BOOL appRunning;
@property (assign, getter=isAppLaunching, setter=setAppLaunching:) BOOL appLaunching;
@end

@implementation DockWidgetItemView
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (nil == self)
        return nil;

    self.appIconContainerView = [[[NSView alloc] initWithFrame:NSZeroRect] autorelease];
    self.appIconContainerView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    self.appIconView = [NSImageView imageViewWithImage:[NSImage imageNamed:NSImageNameApplicationIcon]];
    self.appIconView.imageScaling = NSImageScaleProportionallyDown;

    self.appRunningView = [NSImageView imageViewWithImage:[NSImage imageNamed:@"DockDot"]];
    self.appRunningView.imageScaling = NSImageScaleProportionallyDown;
    self.appRunningView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.appRunningView.hidden = YES;

    [self.appIconContainerView addSubview:self.appIconView];
    [self addSubview:self.appIconContainerView];
    [self addSubview:self.appRunningView];

    return self;
}

- (void)dealloc
{
    [self.bounceAnimation stopAnimation];
    self.bounceAnimation.view = nil;
    self.bounceAnimation = nil;

    self.appIconContainerView = nil;
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

- (BOOL)isAppLaunching
{
    return nil != self.bounceAnimation;
}

- (void)setAppLaunching:(BOOL)value
{
    if (self.isAppLaunching == value)
        return;

    if (value)
    {
        self.bounceAnimation = [[[DockWidgetBounceAnimation alloc]
            initWithDuration:60.0 animationCurve:NSAnimationLinear] autorelease];
        self.bounceAnimation.view = self.appIconContainerView;
        self.bounceAnimation.delegate = self;
        self.bounceAnimation.animationBlockingMode = NSAnimationNonblocking;
        [self.bounceAnimation startAnimation];
    }
    else
    {
        [self.bounceAnimation stopAnimation];
        self.bounceAnimation.view = nil;
        self.bounceAnimation = nil;

        [self.appIconContainerView setFrameOrigin:NSZeroPoint];
        [self.appIconContainerView setNeedsDisplay:YES];
    }
}

- (void)animationDidEnd:(NSAnimation *)animation
{
    [self.bounceAnimation startAnimation];
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

@interface DockWidget () <NSScrubberDataSource, NSScrubberDelegate>
@property (retain) NSArray *defaultApps;
@property (retain) NSArray *runningApps;
@end

@implementation DockWidget
- (void)commonInit
{
    self.customizationLabel = @"Dock";
    NSScrubberFlowLayout *layout = [[[NSScrubberFlowLayout alloc] init] autorelease];
    layout.itemSize = dockItemSize;
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
        selector:@selector(resetRunningApps)
        name:NSWorkspaceWillLaunchApplicationNotification
        object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(resetRunningApps)
        name:NSWorkspaceDidLaunchApplicationNotification
        object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(resetRunningApps)
        name:NSWorkspaceDidTerminateApplicationNotification
        object:nil];
}

- (void)dealloc
{
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        removeObserver:self];

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
    view.appIcon = app.icon;
    view.appRunning = 0 != app.pid;
    //view.appLaunching = app.launching;
    return view;
}

- (void)scrubber:(NSScrubber *)scrubber didSelectItemAtIndex:(NSInteger)index
{
    DockWidgetApplication *app = [self.apps objectAtIndex:index];
    if (nil != app.path)
        [[NSWorkspace sharedWorkspace] openFile:app.path withApplication:nil andDeactivate:YES];
    scrubber.selectedIndex = -1;
}

- (NSArray *)apps
{
    if (nil == self.defaultApps)
    {
        self.runningApps = nil;

        NSMutableArray *newDefaultApps = [NSMutableArray array];
        NSString *defaultAppsFolder = [[NSUserDefaults standardUserDefaults]
            stringForKey:@"defaultAppsFolder"];
        if (nil != defaultAppsFolder)
        {
            NSArray *contents = [[NSFileManager defaultManager]
                contentsOfDirectoryAtPath:defaultAppsFolder error:0];
            contents = [contents sortedArrayUsingSelector:@selector(compare:)];
            for (NSString *c in contents)
            {
                if ([c hasPrefix:@"."])
                    continue;

                NSURL *url = [NSURL
                    URLByResolvingAliasFileAtURL:[NSURL
                        fileURLWithPath:[defaultAppsFolder stringByAppendingPathComponent:c]]
                    options:NSURLBookmarkResolutionWithoutUI|NSURLBookmarkResolutionWithoutMounting
                    error:0];
                DockWidgetApplication *app = [[[DockWidgetApplication alloc] init] autorelease];
                app.name = c;
                app.path = url.path;
                app.icon = [[NSWorkspace sharedWorkspace] iconForFile:app.path];
                app.isDefault = YES;
                [newDefaultApps addObject:app];
            }
        }

        if (0 == newDefaultApps.count)
        {
            NSArray *defaultApps = [[NSUserDefaults standardUserDefaults] arrayForKey:@"defaultApps"];
            for (NSDictionary *a in defaultApps)
            {
                DockWidgetApplication *app = [[[DockWidgetApplication alloc] init] autorelease];
                app.name = [a objectForKey:@"NSApplicationName"];
                app.path = [a objectForKey:@"NSApplicationPath"];
                app.icon = [[NSWorkspace sharedWorkspace] iconForFile:app.path];
                app.isDefault = YES;
                [newDefaultApps addObject:app];
            }
        }

        self.defaultApps = [[newDefaultApps copy] autorelease];
    }

    if (nil == self.runningApps)
    {
        NSMutableDictionary *defaultAppsDict = [NSMutableDictionary dictionary];
        for (DockWidgetApplication *app in self.defaultApps)
        {
            app.pid = 0;
            app.launching = NO;
            [defaultAppsDict setObject:app forKey:app.path];
        }

        NSMutableArray *newRunningApps = [NSMutableArray array];

        NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
        for (NSRunningApplication *a in runningApps)
        {
            if (NSApplicationActivationPolicyRegular != a.activationPolicy)
                continue;

            DockWidgetApplication *app;
            NSString *path = a.bundleURL.path;
            if (nil != (app = [defaultAppsDict objectForKey:path]) && 0 == app.pid)
            {
                app.icon = a.icon;
                app.pid = a.processIdentifier;
                app.launching = !a.finishedLaunching;
                continue;
            }

            app = [[[DockWidgetApplication alloc] init] autorelease];
            app.name = a.localizedName;
            app.path = a.bundleURL.path;
            app.icon = a.icon;
            app.pid = a.processIdentifier;
            app.launching = !a.finishedLaunching;
            [newRunningApps addObject:app];
        }

        self.runningApps = [[newRunningApps copy] autorelease];
    }

    return [self.defaultApps arrayByAddingObjectsFromArray:self.runningApps];
}

- (void)resetDefaultApps
{
    NSScrubber *scrubber = self.view;
    self.defaultApps = nil;
    [scrubber reloadData];
}

- (void)resetRunningApps
{
    @try
    {
        NSScrubber *scrubber = self.view;
        [scrubber performSequentialBatchUpdates:^(void)
        {
            NSUInteger count = scrubber.numberOfItems;
            NSArray *oldApps = [[[NSArray alloc] initWithArray:self.apps copyItems:YES] autorelease];
            self.runningApps = nil;
            NSArray *newApps = self.apps;

            NSMutableDictionary *oldAppsDict = [NSMutableDictionary dictionary];
            for (DockWidgetApplication *oldApp in oldApps)
            {
                NSArray *oldAppsArray = [oldAppsDict objectForKey:oldApp.path];
                if (nil == oldAppsArray)
                    oldAppsArray = [NSArray arrayWithObject:oldApp];
                else
                    oldAppsArray = [oldAppsArray arrayByAddingObject:oldApp];
                [oldAppsDict setObject:oldAppsArray forKey:oldApp.path];
            }

            NSMutableDictionary *newAppsDict = [NSMutableDictionary dictionary];
            for (DockWidgetApplication *newApp in newApps)
            {
                NSArray *newAppsArray = [newAppsDict objectForKey:newApp.path];
                if (nil == newAppsArray)
                    newAppsArray = [NSArray arrayWithObject:newApp];
                else
                    newAppsArray = [newAppsArray arrayByAddingObject:newApp];
                [newAppsDict setObject:newAppsArray forKey:newApp.path];
            }

            /* handle multiple instances for a default app that is terminating */
            for (NSUInteger i = 0; oldApps.count > i; i++)
            {
                DockWidgetApplication *oldApp = [oldApps objectAtIndex:i];
                if (!oldApp.isDefault)
                    break; /* default apps are always first */

                NSArray *newAppsArray = [newAppsDict objectForKey:oldApp.path];
                if (1 <= newAppsArray.count)
                {
                    DockWidgetApplication *newApp = [newAppsArray objectAtIndex:0];
                    NSArray *oldAppsArray = [oldAppsDict objectForKey:oldApp.path];
                    for (NSUInteger j = 1; oldAppsArray.count > j; j++)
                    {
                        DockWidgetApplication *a = [oldAppsArray objectAtIndex:j];
                        if (newApp.pid == a.pid)
                        {
                            pid_t pid = oldApp.pid;
                            oldApp.pid = a.pid;
                            a.pid = pid;

                            BOOL launching = oldApp.launching;
                            oldApp.launching = a.launching;
                            a.launching = launching;

                            break;
                        }
                    }
                }
            }

            /* remove items for old apps that are not in the new apps */
            for (NSUInteger i = oldApps.count - 1; oldApps.count > i; i--)
            {
                DockWidgetApplication *oldApp = [oldApps objectAtIndex:i];
                NSArray *newAppsArray = [newAppsDict objectForKey:oldApp.path];

                BOOL update = YES;
                for (DockWidgetApplication *newApp in newAppsArray)
                    if (0 == oldApp.pid || 0 == newApp.pid || oldApp.pid == newApp.pid)
                    {
                        update = NO;
                        break;
                    }

                if (update)
                {
                    [scrubber removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:i]];
                    count--;
                }
            }

            /* insert items for new apps that are not in the old apps */
            for (NSUInteger i = 0; newApps.count > i; i++)
            {
                DockWidgetApplication *newApp = [newApps objectAtIndex:i];
                NSArray *oldAppsArray = [oldAppsDict objectForKey:newApp.path];

                BOOL update = YES;
                for (DockWidgetApplication *oldApp in oldAppsArray)
                    if (0 == oldApp.pid || 0 == newApp.pid || oldApp.pid == newApp.pid)
                    {
                        update = NO;
                        break;
                    }

                if (update)
                {
                    [scrubber insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:count]];
                    count++;
                }
            }

            for (NSUInteger i = 0; oldApps.count > i; i++)
            {
                DockWidgetApplication *oldApp = [oldApps objectAtIndex:i];
                NSArray *newAppsArray = [newAppsDict objectForKey:oldApp.path];

                BOOL update = NO;
                for (DockWidgetApplication *newApp in newAppsArray)
                    if (oldApp.pid != newApp.pid || oldApp.launching != newApp.launching)
                    {
                        update = YES;
                        break;
                    }

                if (update)
                    [scrubber reloadItemsAtIndexes:[NSIndexSet indexSetWithIndex:i]];
            }
        }];
    }
    @catch (NSException *ex)
    {
        NSLog(@"%@", ex);

        NSScrubber *scrubber = self.view;
        self.runningApps = nil;
        [scrubber reloadData];
    }
}
@end
