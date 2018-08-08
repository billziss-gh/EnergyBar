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

@interface DockWidgetApplication : NSObject
@property (retain) NSString *name;
@property (retain) NSString *path;
@property (retain) NSImage *icon;
@property (assign) BOOL running;
@property (assign) BOOL active;
@end

@implementation DockWidgetApplication
@end

@interface DockWidget () <NSScrubberDataSource, NSScrubberFlowLayoutDelegate>
@property (retain) NSShadow *shadow;
@property (retain) DockWidgetApplication *separator;
@property (retain) NSArray *defaultApps;
@property (retain) NSArray *runningApps;
@end

static NSString *dockItemIdentifier = @"dockItem";

static NSSize dockItemSize = { 50, 30 };
static NSSize dockSeparatorSize = { 10, 30 };
static NSSize dockIconSize = { 28, 28 };

@implementation DockWidget
- (void)commonInit
{
    self.shadow = [[[NSShadow alloc] init] autorelease];
    self.shadow.shadowOffset = NSMakeSize(0, -1);
    self.shadow.shadowBlurRadius = 5;
    self.shadow.shadowColor = [NSColor systemBlueColor];
    self.separator = [[[DockWidgetApplication alloc] init] autorelease];

    self.customizationLabel = @"Dock";
    NSScrubberFlowLayout *layout = [[[NSScrubberFlowLayout alloc] init] autorelease];
    NSScrubber *scrubber = [[[NSScrubber alloc] initWithFrame:NSMakeRect(0, 0, 200, 30)] autorelease];
    [scrubber registerClass:[NSScrubberImageItemView class] forItemIdentifier:dockItemIdentifier];
    scrubber.dataSource = self;
    scrubber.delegate = self;
    scrubber.mode = NSScrubberModeFixed;
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
#if 0
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(didActivateApplication:)
        name:NSWorkspaceDidActivateApplicationNotification
        object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(didDeactivateApplication:)
        name:NSWorkspaceDidDeactivateApplicationNotification
        object:nil];
#endif
}

- (void)dealloc
{
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        removeObserver:self];

    self.shadow = nil;
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
    NSScrubberImageItemView *view = [scrubber makeItemWithIdentifier:dockItemIdentifier owner:nil];
    view.imageView.imageScaling = NSImageScaleProportionallyDown;
    view.imageView.shadow = nil;
    DockWidgetApplication *app = [self.apps objectAtIndex:index];
    if (nil != app.path)
    {
        view.image = app.icon;
        if (app.running)
            view.imageView.shadow = self.shadow;
    }
    else
        view.image = [NSImage imageNamed:NSImageNameTouchBarPlayheadTemplate];
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
    NSLog(@"didLaunchApplication: %@", notification);
    self.runningApps = nil;
    [(NSScrubber *)self.view reloadData];
}

- (void)didTerminateApplication:(NSNotification *)notification
{
    NSLog(@"didTerminateApplication: %@", notification);
    self.runningApps = nil;
    [(NSScrubber *)self.view reloadData];
}

#if 0
- (void)didActivateApplication:(NSNotification *)notification
{
    NSLog(@"didActivateApplication: %@", notification);
}

- (void)didDeactivateApplication:(NSNotification *)notification
{
    NSLog(@"didDeactivateApplication: %@", notification);
}
#endif

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
            app.icon = [self resizedImage:app.icon withSize:dockIconSize];
            [newDefaultApps addObject:app];
        }
        self.defaultApps = [newDefaultApps copy];
    }

    if (nil == self.runningApps)
    {
        NSMutableDictionary *defaultAppsDict = [NSMutableDictionary dictionary];
        for (DockWidgetApplication *app in self.defaultApps)
        {
            app.running = NO;
            app.active = NO;
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
                app.active = a.active;
                continue;
            }

            app = [[[DockWidgetApplication alloc] init] autorelease];
            app.name = a.localizedName;
            app.path = a.bundleURL.path;
            app.icon = a.icon;
            app.icon = [self resizedImage:app.icon withSize:dockIconSize];
            app.running = YES;
            app.active = a.active;
            [newRunningApps addObject:app];
        }
        self.runningApps = [newRunningApps copy];
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

- (NSImage *)resizedImage:(NSImage *)image withSize:(NSSize)newSize
{
    NSSize size = image.size;
    NSImage *newImage = [[[NSImage alloc] initWithSize:newSize] autorelease];
    [newImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [image
        drawInRect:NSMakeRect(0, 0, newSize.width, newSize.height)
        fromRect:NSMakeRect(0, 0, size.width, size.height)
        operation:NSCompositingOperationSourceOver
        fraction:1.0];
    [newImage unlockFocus];
    return newImage;
}
@end
