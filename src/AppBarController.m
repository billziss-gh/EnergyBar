/**
 * @file AppBarController.m
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

#import "AppBarController.h"
#import "ClockWidget.h"
#import "DockWidget.h"

@interface AppBarController () <NSTouchBarDelegate>
@end

@implementation AppBarController
{
    NSMutableDictionary *_items;
}

- (id)init
{
    self = [super init];
    if (nil == self)
        return nil;

    _items = [[NSMutableDictionary alloc] init];

    return self;
}

- (void)dealloc
{
    [_items release];

    [super dealloc];
}

- (void)awakeFromNib
{
    self.touchBar.defaultItemIdentifiers = [NSArray arrayWithObjects:
        @"EscKey",
        @"ActiveApp",
        @"Dock",
        @"Control",
        @"Clock",
        nil];
    self.touchBar.customizationAllowedItemIdentifiers = [NSArray arrayWithObjects:
        @"Dock",
        @"ActiveApp",
        @"EscKey",
        @"Control",
        @"Clock",
        nil];

    [[self.touchBar itemForIdentifier:@"Clock"]
        setPressTarget:self
        action:@selector(showMainWindow:)];

    [super awakeFromNib];
}

- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar
    makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    NSTouchBarItem *item = [_items objectForKey:identifier];
    if (nil == item)
    {
        NSArray *components = [identifier componentsSeparatedByString:@" "];
        NSString *widgetClass = [[components objectAtIndex:0] stringByAppendingString:@"Widget"];
        item = [[[NSClassFromString(widgetClass) alloc] initWithIdentifier:identifier] autorelease];
        [_items setObject:item forKey:identifier];
    }
    return item;
}

- (IBAction)appsFolderAction:(id)sender
{
    [[self.touchBar itemForIdentifier:@"Dock"] resetDefaultApps];
}

- (IBAction)resetAppsFromDockAction:(id)sender
{
    NSString *defaultAppsFolder = [[NSUserDefaults standardUserDefaults]
        stringForKey:@"defaultAppsFolder"];

    NSArray *contents = nil;
    NSUInteger appCount = 0;
    if (nil != defaultAppsFolder)
    {
        contents = [[NSFileManager defaultManager]
            contentsOfDirectoryAtPath:defaultAppsFolder error:0];
        for (NSString *c in contents)
        {
            if ([c hasPrefix:@"."])
                continue;

            appCount++;
        }
    }

    if (0 != appCount)
    {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        alert.alertStyle = NSAlertStyleWarning;
        alert.messageText = @"Reset Apps";
        alert.informativeText = @"This will remove any existing applications in the Touch Bar Dock"
            " and will replace them with ones from the macOS Dock."
            " Are you sure you want to proceed?";
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        NSModalResponse resp = [alert runModal];
        /* HACK:
         * -[NSAlert runModal] seems to overwrite our Touch Bar.
         * So we dismiss it and then present it again! (Just presenting it does not do it!)
         */
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:0];
        [self performSelector:@selector(present) withObject:nil afterDelay:0];
        if (NSAlertFirstButtonReturn != resp)
            return;
    }

    for (NSString *c in contents)
    {
        if ([c hasPrefix:@"."])
            continue;

        [[NSFileManager defaultManager]
            removeItemAtPath:[defaultAppsFolder stringByAppendingPathComponent:c]
            error:0];
    }

    NSString *finderPath = [[[[NSUserDefaults standardUserDefaults]
        objectForKey:@"defaultApps"] objectAtIndex:0] objectForKey:@"NSApplicationPath"];
    finderPath = [[NSURL fileURLWithPath:finderPath] absoluteString];
    NSDictionary *finderDict = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Finder", @"file-label",
            [NSDictionary
                dictionaryWithObjectsAndKeys:finderPath, @"_CFURLString", nil], @"file-data",
            nil], @"tile-data",
        nil];

    NSUserDefaults *dockDefaults = [[[NSUserDefaults alloc] init] autorelease];
    NSDictionary *dockDict = [dockDefaults persistentDomainForName:@"com.apple.dock"];
    NSArray *dockApps = [[NSArray arrayWithObject:finderDict]
        arrayByAddingObjectsFromArray:[dockDict objectForKey:@"persistent-apps"]];
    NSUInteger order = 0;
    for (NSDictionary *a in dockApps)
    {
        a = [a objectForKey:@"tile-data"];
        NSString *name = [a objectForKey:@"file-label"];
        NSString *urlstr = [[a objectForKey:@"file-data"] objectForKey:@"_CFURLString"];
        if (nil == name || nil == urlstr)
            continue;

        name = [NSString stringWithFormat:@"%02u-%@", (unsigned)order, name];

        NSURL *url = [NSURL URLWithString:urlstr];
        if (nil == url)
            continue;

        NSData *data = [url
            bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
            includingResourceValuesForKeys:nil
            relativeToURL:nil
            error:0];
        [NSURL
            writeBookmarkData:data
            toURL:[NSURL fileURLWithPath:[defaultAppsFolder stringByAppendingPathComponent:name]]
            options:NSURLBookmarkCreationSuitableForBookmarkFile
            error:0];

        order += 10;
    }

    [[self.touchBar itemForIdentifier:@"Dock"]
        resetDefaultApps];
}

- (IBAction)showAppsFolderAction:(id)sender
{
    [[NSWorkspace sharedWorkspace]
        openFile:[[NSUserDefaults standardUserDefaults] objectForKey:@"defaultAppsFolder"]];
}

- (IBAction)showMainWindow:(id)sender
{
    [[NSApp.windows objectAtIndex:0] makeKeyAndOrderFront:nil];
}
@end
