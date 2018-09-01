/**
 * @file AppController.m
 *
 * @copyright 2018 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
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
@property (retain) NSString *origDefaultAppsFolder;
@property (assign) IBOutlet TouchBarController *touchBarController;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *versionLabel;
@property (assign) IBOutlet NSButton *resetFromDockButton;
@property (assign) IBOutlet NSButton *toggleMacOSDockButton;
@property (assign) IBOutlet NSButton *loginItemButton;
@property (assign) IBOutlet NSButton *sourceLinkButton;
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

    self.origDefaultAppsFolder = nil;

    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSMutableDictionary *defaults = [NSMutableDictionary
        dictionaryWithContentsOfFile:[[NSBundle mainBundle]
        pathForResource:@"defaults"
        ofType:@"plist"]];
    self.origDefaultAppsFolder = [[defaults objectForKey:@"defaultAppsFolder"]
        stringByExpandingTildeInPath];
    [defaults setObject:self.origDefaultAppsFolder forKey:@"defaultAppsFolder"];
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
    [self enableResetFromDockButton];

    NSMutableParagraphStyle *sourceLinkPara = [[[NSParagraphStyle defaultParagraphStyle]
        mutableCopy] autorelease];
    sourceLinkPara.alignment = self.sourceLinkButton.alignment;
    NSDictionary *sourceLinkAttr = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor blueColor], NSForegroundColorAttributeName,
        self.sourceLinkButton.font, NSFontAttributeName,
        sourceLinkPara, NSParagraphStyleAttributeName,
        nil];
    self.sourceLinkButton.attributedTitle = [[[NSAttributedString alloc]
        initWithString:self.sourceLinkButton.title attributes:sourceLinkAttr] autorelease];

    NSView *contentView = self.window.contentView;
    NSView *superView = contentView.superview;
    if ([superView respondsToSelector:@selector(_addKnownSubview:)])
        [superView _addKnownSubview:contentView];
    else
        [superView addSubview:contentView];

    [self updateToggleMacOSDockButton];
    [self updateDateFormat];

    self.loginItemButton.state = IsLoginItem([[NSBundle mainBundle] bundleURL]) ?
        NSControlStateValueOn : NSControlStateValueOff;

    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    if (nil != version)
        version = [self.versionLabel.stringValue
            stringByReplacingOccurrencesOfString:@"0.0" withString:version];
    else
        version = @"";
    self.versionLabel.stringValue = version;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"mainWindowHidden"])
        [self showMainWindow:nil];

    [[self.touchBarController.touchBar itemForIdentifier:@"Clock"]
        setPressTarget:self
        action:@selector(showMainWindow:)];

    if (![self.touchBarController present])
    {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        alert.alertStyle = NSAlertStyleCritical;
        alert.messageText = @"Touch Bar API not found!";
        alert.informativeText = @"The EnergyBar application will now exit.";
        [alert runModal];
        [NSApp terminate:nil];
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    [self showMainWindow:nil];
    return NO;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (!self.window.visible)
        return NSTerminateNow;

    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    alert.alertStyle = NSAlertStyleWarning;
    alert.messageText = @"Terminate EnergyBar?";
    alert.informativeText = @"Are you sure you want to terminate EnergyBar? "
        "Your Touch Bar will revert to its normal state.";
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse resp)
    {
        [sender replyToApplicationShouldTerminate:NSAlertFirstButtonReturn == resp];
    }];
    return NSTerminateLater;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self.touchBarController dismiss];
}

- (void)windowWillClose:(NSNotification *)notification
{
    //NSApp.activationPolicy = NSApplicationActivationPolicyProhibited;
}

- (void)showMainWindow:(id)sender
{
    //NSApp.activationPolicy = NSApplicationActivationPolicyRegular;
    [[NSApp.windows objectAtIndex:0] makeKeyAndOrderFront:nil];
    if (nil != sender)
        [NSApp activateIgnoringOtherApps:YES];
}

- (void)fsnotify:(const char *)path
{
    [[self.touchBarController.touchBar itemForIdentifier:@"Dock"] reset];
}

- (IBAction)appsFolderAction:(id)sender
{
    FSNotifyStop(_stream);
    _stream = FSNotifyStart([[[NSUserDefaults standardUserDefaults]
        stringForKey:@"defaultAppsFolder"] UTF8String], AppControllerFSNotify, self);
    [self enableResetFromDockButton];

    [[self.touchBarController.touchBar itemForIdentifier:@"Dock"] reset];
}

- (void)enableResetFromDockButton
{
    NSString *defaultAppsFolder = [[NSUserDefaults standardUserDefaults]
        stringForKey:@"defaultAppsFolder"];
    self.resetFromDockButton.enabled = [defaultAppsFolder isEqualToString:self.origDefaultAppsFolder];
}

- (IBAction)resetFromDockAction:(id)sender
{
    NSString *defaultAppsFolder = [[NSUserDefaults standardUserDefaults]
        stringForKey:@"defaultAppsFolder"];
    if (nil == defaultAppsFolder)
        return;

    NSUInteger itemCount = 0;
    NSArray *contents = [[NSFileManager defaultManager]
        contentsOfDirectoryAtPath:defaultAppsFolder error:0];
    for (NSString *c in contents)
    {
        if ([c hasPrefix:@"."])
            continue;

        itemCount++;
    }

    if (0 != itemCount)
    {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        alert.alertStyle = NSAlertStyleWarning;
        alert.messageText = @"Reset Apps";
        alert.informativeText = @"This will remove any existing applications in the EnergyBar Dock"
            " and will replace them with ones from the macOS Dock."
            " Are you sure you want to proceed?";
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        NSModalResponse resp = [alert runModal];
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

    NSUserDefaults *dockDefaults = [[[NSUserDefaults alloc]
        initWithSuiteName:@"com.apple.dock"] autorelease];
    NSArray *dockItems = [NSArray arrayWithObject:finderDict];
    dockItems = [dockItems
        arrayByAddingObjectsFromArray:[dockDefaults objectForKey:@"persistent-apps"]];
    dockItems = [dockItems
        arrayByAddingObjectsFromArray:[dockDefaults objectForKey:@"persistent-others"]];
    NSUInteger order = 0;
    for (NSDictionary *item in dockItems)
    {
        item = [item objectForKey:@"tile-data"];
        NSString *name = [item objectForKey:@"file-label"];
        NSString *urlstr = [[item objectForKey:@"file-data"] objectForKey:@"_CFURLString"];
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

- (IBAction)showsRunningAppsAction:(id)sender
{
    [[self.touchBarController.touchBar itemForIdentifier:@"Dock"] reset];
}

- (IBAction)showsTrashAction:(id)sender
{
    [[self.touchBarController.touchBar itemForIdentifier:@"Dock"] reset];
}

- (IBAction)shows24HourClockAction:(id)sender
{
    [[self.touchBarController.touchBar itemForIdentifier:@"Dock"] reset];
    [self updateDateFormat];
}

- (void)updateDateFormat
{
    ClockWidget *clock = [self.touchBarController.touchBar itemForIdentifier:@"Clock"];
    clock.formatter.dateFormat =
        [[NSUserDefaults standardUserDefaults] boolForKey:@"shows24HourClock"] ?
            @"HH:mm" :
            @"h:mm a";
    
    // stop and start the clock to have it redraw itself
    [clock stop];
    [clock start];
}

- (void)updateToggleMacOSDockButton
{
    NSUserDefaults *dockDefaults = [[[NSUserDefaults alloc]
        initWithSuiteName:@"com.apple.dock"] autorelease];
    NSString *showhide = 60 <= [dockDefaults integerForKey:@"autohide-delay"] ? @"Show" : @"Hide";
    self.toggleMacOSDockButton.title = [self.toggleMacOSDockButton.alternateTitle
        stringByReplacingOccurrencesOfString:@"Toggle" withString:showhide];
}

- (void)enableToggleMacOSDockButton
{
    self.toggleMacOSDockButton.enabled = YES;
    [self updateToggleMacOSDockButton];
}

- (IBAction)toggleMacOSDockAction:(id)sender
{
    NSUserDefaults *dockDefaults = [[[NSUserDefaults alloc]
        initWithSuiteName:@"com.apple.dock"] autorelease];
    if (60 <= [dockDefaults integerForKey:@"autohide-delay"])
    {
        [dockDefaults setBool:NO forKey:@"autohide"];
        [dockDefaults removeObjectForKey:@"autohide-delay"];
    }
    else
    {
        [dockDefaults setInteger:1000000 forKey:@"autohide-delay"];
        [dockDefaults setBool:YES forKey:@"autohide"];
    }
    [dockDefaults synchronize];

    /* give some visual feedback */
    self.toggleMacOSDockButton.enabled = NO;
    [self performSelector:@selector(enableToggleMacOSDockButton) withObject:nil afterDelay:1.0];

    NSRunningApplication *dockApp = [[NSRunningApplication
        runningApplicationsWithBundleIdentifier:@"com.apple.dock"] firstObject];
    [dockApp terminate];
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
