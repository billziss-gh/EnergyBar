/**
 * @file AppController.m
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

#import "AppController.h"
#import "ClockWidget.h"
#import "DockWidget.h"
#import "FSNotify.h"
#import "LoginItem.h"
#import "TouchBarController.h"

@interface NSView ()
- (void)_addKnownSubview:(NSView *)subview;
@end

@interface AppController () <NSApplicationDelegate, NSWindowDelegate>
- (void)fsnotify:(const char *)path;
@property (assign) IBOutlet TouchBarController *touchBarController;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *loginItemButton;
@end

static void AppControllerFSNotify(const char *path, void *data)
{
    [(id)data fsnotify:path];
}

@implementation AppController
{
    void *_stream;
}

- (void)dealloc
{
    FSNotifyStop(_stream);

    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSMutableDictionary *defaults = [NSMutableDictionary
        dictionaryWithContentsOfFile:[[NSBundle mainBundle]
        pathForResource:@"defaults"
        ofType:@"plist"]];
    [defaults
        setObject:[[defaults objectForKey:@"defaultAppsFolder"] stringByExpandingTildeInPath]
        forKey:@"defaultAppsFolder"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    NSString *defaultAppsFolder = [[NSUserDefaults standardUserDefaults]
        stringForKey:@"defaultAppsFolder"];
    if (nil != defaultAppsFolder)
    {
        [[NSFileManager defaultManager]
            createDirectoryAtPath:defaultAppsFolder
            withIntermediateDirectories:YES
            attributes:nil
            error:nil];
    }

    FSNotifyStop(_stream);
    _stream = FSNotifyStart([defaultAppsFolder UTF8String], AppControllerFSNotify, self);

    NSView *contentView = self.window.contentView;
    NSView *superView = contentView.superview;
    if ([superView respondsToSelector:@selector(_addKnownSubview:)])
        [superView _addKnownSubview:contentView];
    else
        [superView addSubview:contentView];

    NSApp.touchBar = self.touchBarController.touchBar;
    [[self.touchBarController.touchBar itemForIdentifier:@"Clock"]
        setPressTarget:self
        action:@selector(showMainWindow:)];
    [self performSelector:@selector(presentTouchBar) withObject:nil afterDelay:0];

    self.loginItemButton.state = IsLoginItem([[NSBundle mainBundle] bundleURL]) ?
        NSControlStateValueOn : NSControlStateValueOff;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"mainWindowHidden"])
        [self showMainWindow:nil];
}


- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self.touchBarController dismiss];
}

- (void)presentTouchBar
{
    if (![self.touchBarController present])
    {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        alert.alertStyle = NSAlertStyleCritical;
        alert.messageText = @"Touch Bar API not found!";
        alert.informativeText = @"The Touch Bar Dock application will now exit.";
        [alert runModal];
        [NSApp terminate:nil];
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
    NSApp.activationPolicy = NSApplicationActivationPolicyProhibited;
}

- (void)showMainWindow:(id)sender
{
    NSApp.activationPolicy = NSApplicationActivationPolicyRegular;
    [[NSApp.windows objectAtIndex:0] makeKeyAndOrderFront:nil];
}

- (void)fsnotify:(const char *)path
{
    [[self.touchBarController.touchBar itemForIdentifier:@"Dock"] resetDefaultApps];
}

- (IBAction)appsFolderAction:(id)sender
{
    FSNotifyStop(_stream);
    _stream = FSNotifyStart([[[NSUserDefaults standardUserDefaults]
        stringForKey:@"defaultAppsFolder"] UTF8String], AppControllerFSNotify, self);

    [[self.touchBarController.touchBar itemForIdentifier:@"Dock"] resetDefaultApps];
}

- (IBAction)resetAppsFromDockAction:(id)sender
{
    NSString *defaultAppsFolder = [[NSUserDefaults standardUserDefaults]
        stringForKey:@"defaultAppsFolder"];
    if (nil == defaultAppsFolder)
        return;

    NSUInteger appCount = 0;
    NSArray *contents = [[NSFileManager defaultManager]
        contentsOfDirectoryAtPath:defaultAppsFolder error:0];
    for (NSString *c in contents)
    {
        if ([c hasPrefix:@"."])
            continue;

        appCount++;
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
        [self.touchBarController performSelector:@selector(dismiss) withObject:nil afterDelay:0];
        [self.touchBarController performSelector:@selector(present) withObject:nil afterDelay:0];
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
}

- (IBAction)showAppsFolderAction:(id)sender
{
    NSString *defaultAppsFolder = [[NSUserDefaults standardUserDefaults]
        stringForKey:@"defaultAppsFolder"];
    if (nil == defaultAppsFolder)
        return;

    [[NSWorkspace sharedWorkspace] openFile:defaultAppsFolder];
}

- (IBAction)loginItemAction:(id)sender
{
    SetLoginItem([[NSBundle mainBundle] bundleURL],
        NSControlStateValueOff != self.loginItemButton.state);
}

- (IBAction)sourceLinkAction:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/billziss-gh"]];
}
@end
