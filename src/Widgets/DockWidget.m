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

@interface DockWidget_Application : NSObject
@property (retain) NSString *name;
@property (retain) NSString *path;
@property (retain) NSImage *icon;
@property (assign) BOOL running;
@end

@implementation DockWidget_Application
@end

@interface DockWidget () <NSScrubberDataSource, NSScrubberFlowLayoutDelegate>
@property (retain) DockWidget_Application *separator;
@property (retain) NSArray *defaultApps;
@property (retain) NSArray *runningApps;
@end

static NSString *dockItemIdentifier = @"dockItem";

static NSSize dockItemSize = { 50, 30 };
static NSSize dockSeparatorSize = { 10, 30 };

@implementation DockWidget
- (void)commonInit
{
    self.separator = [[[DockWidget_Application alloc] init] autorelease];
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
}

- (void)dealloc
{
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
    view.image = [[self.apps objectAtIndex:index] icon];
    return view;
}

- (NSSize)scrubber:(NSScrubber *)scrubber
    layout:(NSScrubberFlowLayout *)layout
    sizeForItemAtIndex:(NSInteger)index
{
    DockWidget_Application *app = [self.apps objectAtIndex:index];
    if (nil != app.path)
        return dockItemSize;
    else
        return dockSeparatorSize;
}

- (void)scrubber:(NSScrubber *)scrubber
    didSelectItemAtIndex:(NSInteger)index
{
    DockWidget_Application *app = [self.apps objectAtIndex:index];
    if (nil != app.path)
        [[NSWorkspace sharedWorkspace] launchApplication:app.path];
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
            DockWidget_Application *app = [[[DockWidget_Application alloc] init] autorelease];
            app.name = [a objectForKey:@"NSApplicationName"];
            app.path = [a objectForKey:@"NSApplicationPath"];
            app.icon = [[NSWorkspace sharedWorkspace] iconForFile:app.path];
            [newDefaultApps addObject:app];
        }
        self.defaultApps = [newDefaultApps copy];
    }

    if (nil == self.runningApps)
    {
        NSMutableDictionary *defaultAppsDict = [NSMutableDictionary dictionary];
        for (DockWidget_Application *app in self.defaultApps)
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

            DockWidget_Application *app;
            NSString *path = a.bundleURL.path;
            if (nil != (app = [defaultAppsDict objectForKey:path]))
            {
                app.running = YES;
                continue;
            }

            app = [[[DockWidget_Application alloc] init] autorelease];
            app.name = a.localizedName;
            app.path = a.bundleURL.path;
            app.icon = a.icon;
            app.running = YES;
            [newRunningApps addObject:app];
        }
        self.runningApps = [newRunningApps copy];
    }

    if (0 < self.defaultApps.count && 0 < self.runningApps.count)
        return [[self.defaultApps arrayByAddingObject:self.separator]
            arrayByAddingObjectsFromArray:self.runningApps];
    else if (0 < self.defaultApps.count)
        return self.defaultApps;
    else
        return self.runningApps;
}
@end
