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
#import <OctoFeed/OctoFeed.h>
#import "ClockWidget.h"
#import "DockWidget.h"
#import "FSNotify.h"
#import "LoginItem.h"
#import "NowPlayingWidget.h"
#import "TouchBarController.h"
#import "WeatherWidget.h"
#import "System/NSTouchBar+SystemModal.h"

@interface AppController () <NSApplicationDelegate, NSWindowDelegate>
- (void)fsnotify:(const char *)path;
@property (retain) NSString *standardDefaultAppsFolder;
@property (assign) IBOutlet TouchBarController *touchBarController;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView *generalView;
@property (assign) IBOutlet NSView *widgetsView;
@property (assign) IBOutlet NSView *advancedView;
@property (assign) IBOutlet NSTextField *versionLabel;
@property (assign) IBOutlet NSButton *versionButton;
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
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

    FSNotifyStop(_stream);

    self.standardDefaultAppsFolder = nil;

    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSMutableDictionary *defaults = [NSMutableDictionary
        dictionaryWithContentsOfFile:[[NSBundle mainBundle]
        pathForResource:@"defaults"
        ofType:@"plist"]];
    self.standardDefaultAppsFolder = [[defaults objectForKey:@"defaultAppsFolder"]
        stringByExpandingTildeInPath];
    [defaults setObject:self.standardDefaultAppsFolder forKey:@"defaultAppsFolder"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"automaticUpdates"])
        [[OctoFeed mainBundleFeed] activateWithInstallPolicy:OctoFeedInstallAtActivation];

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

    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(settingsChange:)
        name:NSWorkspaceDidWakeNotification
        object:nil];

    self.window.toolbar.selectedItemIdentifier = @"General";
    NSMutableParagraphStyle *sourceLinkPara = [[[NSParagraphStyle defaultParagraphStyle]
        mutableCopy] autorelease];
    sourceLinkPara.alignment = self.sourceLinkButton.alignment;
    NSDictionary *sourceLinkAttr = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor linkColor], NSForegroundColorAttributeName,
        self.sourceLinkButton.font, NSFontAttributeName,
        sourceLinkPara, NSParagraphStyleAttributeName,
        nil];
    self.sourceLinkButton.attributedTitle = [[[NSAttributedString alloc]
        initWithString:self.sourceLinkButton.title attributes:sourceLinkAttr] autorelease];
    [self updateToggleMacOSDockButton];
    self.loginItemButton.state = IsLoginItem([[NSBundle mainBundle] bundleURL]) ?
        NSControlStateValueOn : NSControlStateValueOff;
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *versionString = version;
    if (nil != versionString)
        versionString = [self.versionLabel.stringValue
            stringByReplacingOccurrencesOfString:@"0.0" withString:version];
    else
        versionString = @"";
    self.versionLabel.stringValue = versionString;

    NSString *lastVersion = [[NSUserDefaults standardUserDefaults] stringForKey:@"LastVersion"];
    if (nil == lastVersion || ![version isEqualToString:lastVersion])
        self.versionButton.hidden = NO;

    [self setContentView:self.generalView];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"mainWindowHidden"])
        [self showMainWindow:nil];

    [[self.touchBarController.touchBar itemForIdentifier:@"Clock"]
        setPressTarget:self
        action:@selector(showMainWindow:)];
    [self settingsChange:nil];

    DFRSystemModalShowsCloseBoxWhenFrontMost(YES);
    BOOL showSystemControl = [[NSUserDefaults standardUserDefaults] boolForKey:@"showsSystemControl"];
    [self.touchBarController setPlacement:(!showSystemControl)];
    [self addControlButton];
    if (!showSystemControl) {
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
}

- (void)addControlButton {
    NSTouchBarItemIdentifier identifier = @"blissziss.energybar.controlbutton";
    NSCustomTouchBarItem *button = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
    NSImage *icon = [NSImage imageNamed:@"AppIcon"];
    button.view = [NSButton buttonWithImage:icon target:self.touchBarController action:@selector(present)];
    [NSTouchBarItem addSystemTrayItem:button];
    DFRElementSetControlStripPresenceForIdentifier(identifier, YES);
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

- (void)setContentView:(NSView *)view
{
    NSWindow *window = self.window;
    CGRect frameRect = window.frame;
    CGSize frameSize = nil != view ?
        [window frameRectForContentRect:view.bounds].size :
        frameRect.size;
    frameRect.origin = CGPointMake(
        frameRect.origin.x, frameRect.origin.y + frameRect.size.height - frameSize.height);
    frameRect.size = frameSize;
    window.contentView = nil;
    [window setFrame:frameRect display:YES animate:window.isVisible];
    window.contentView = view;
}

- (void)showMainWindow:(id)sender
{
    [[NSApp.windows objectAtIndex:0] makeKeyAndOrderFront:nil];
    if (nil != sender)
        [NSApp activateIgnoringOtherApps:YES];
}

- (void)fsnotify:(const char *)path
{
    [[self.touchBarController.touchBar itemForIdentifier:@"Dock"] reset];
}

- (void)settingsChange:(NSNotification *)notification
{
    [self clockWidgetSettingsChange:nil];
    [self weatherWidgetSettingsChange:nil];
    [self nowPlayingWidgetSettingsChange:nil];
}

- (IBAction)toolbarItemAction:(id)sender
{
    switch ([sender tag])
    {
    case 0:
        [self setContentView:self.generalView];
        break;
    case 1:
        [self setContentView:self.widgetsView];
        break;
    case 2:
        [self setContentView:self.advancedView];
        break;
    }
}

- (IBAction)sourceItemAction:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/billziss-gh"]];
}

- (IBAction)appsFolderAction:(id)sender
{
    FSNotifyStop(_stream);
    _stream = FSNotifyStart([[[NSUserDefaults standardUserDefaults]
        stringForKey:@"defaultAppsFolder"] UTF8String], AppControllerFSNotify, self);

    [[self.touchBarController.touchBar itemForIdentifier:@"Dock"] reset];
}

- (IBAction)resetFromDockAction:(id)sender
{
    [[NSFileManager defaultManager]
        createDirectoryAtPath:self.standardDefaultAppsFolder
        withIntermediateDirectories:YES
        attributes:nil
        error:nil];

    NSUInteger itemCount = 0;
    NSArray *contents = [[NSFileManager defaultManager]
        contentsOfDirectoryAtPath:self.standardDefaultAppsFolder error:0];
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
            removeItemAtPath:[self.standardDefaultAppsFolder stringByAppendingPathComponent:c]
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
            toURL:[NSURL fileURLWithPath:[self.standardDefaultAppsFolder stringByAppendingPathComponent:name]]
            options:NSURLBookmarkCreationSuitableForBookmarkFile
            error:0];

        order += 10;
    }

    [[NSUserDefaults standardUserDefaults]
        setObject:self.standardDefaultAppsFolder forKey:@"defaultAppsFolder"];
    [[self.touchBarController.touchBar itemForIdentifier:@"Dock"] reset];
}

- (IBAction)showAppsFolderAction:(id)sender
{
    NSString *defaultAppsFolder = [[NSUserDefaults standardUserDefaults]
        stringForKey:@"defaultAppsFolder"];
    if (nil == defaultAppsFolder)
        return;

    [[NSWorkspace sharedWorkspace] openFile:defaultAppsFolder];
}

- (IBAction)dockWidgetSettingsChange:(id)sender
{
    [[self.touchBarController.touchBar itemForIdentifier:@"Dock"] reset];
}

- (IBAction)touchbarSettingsChange:(id)sender {
    BOOL showSystemControl = [[NSUserDefaults standardUserDefaults] boolForKey:@"showsSystemControl"];
    [self.touchBarController setPlacement:(!showSystemControl)];
    if (showSystemControl) {
        [self.touchBarController dismiss];
    } else {
        [self.touchBarController present];
    }
}

- (IBAction)clockWidgetSettingsChange:(id)sender
{
    ClockWidget *clock = [self.touchBarController.touchBar itemForIdentifier:@"Clock"];
    clock.formatter.dateFormat =
        [[NSUserDefaults standardUserDefaults] boolForKey:@"shows24HourClock"] ?
            @"H:mm" :
            @"h:mm a";
    clock.showsBatteryStatus = [[NSUserDefaults standardUserDefaults] boolForKey:@"clockShowsBatteryStatus"];
    clock.showsBatteryTimeRemaining = [[NSUserDefaults standardUserDefaults]
        boolForKey:@"clockShowsBatteryTimeRemaining"];
    clock.showsWeather = [[NSUserDefaults standardUserDefaults] boolForKey:@"clockShowsWeatherOnTap"];
    [clock resetClock];
}

- (IBAction)weatherWidgetSettingsChange:(id)sender
{
    NSUInteger temperatureUnit =
        [[NSUserDefaults standardUserDefaults] boolForKey:@"weatherShowsFahrenheit"] ? 'F' : 'C';

    ClockWidget *clock = [self.touchBarController.touchBar itemForIdentifier:@"Clock"];
    clock.temperatureUnit = temperatureUnit;
    [clock resetWeather];

    WeatherWidget *weather = [self.touchBarController.touchBar itemForIdentifier:@"Weather"];
    weather.temperatureUnit = temperatureUnit;
    [weather resetWeather];
}

- (IBAction)nowPlayingWidgetSettingsChange:(id)sender
{
    NowPlayingWidget *widget = [self.touchBarController.touchBar itemForIdentifier:@"NowPlaying"];
    widget.showsActiveAppOnTap = [[NSUserDefaults standardUserDefaults]
        boolForKey:@"showsActiveAppOnTap"];
    widget.showsSmallWidget = [[NSUserDefaults standardUserDefaults]
        boolForKey:@"nowPlayingShowsSmallWidget"];
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
        [dockDefaults setBool:NO forKey:@"no-bouncing"];
        [dockDefaults setBool:NO forKey:@"autohide"];
        [dockDefaults removeObjectForKey:@"autohide-delay"];
    }
    else
    {
        [dockDefaults setInteger:1000000 forKey:@"autohide-delay"];
        [dockDefaults setBool:YES forKey:@"autohide"];
        [dockDefaults setBool:YES forKey:@"no-bouncing"];
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

- (IBAction)automaticUpdatesAction:(id)sender
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"automaticUpdates"])
        [[OctoFeed mainBundleFeed] activateWithInstallPolicy:OctoFeedInstallAtActivation];
    else
        [[OctoFeed mainBundleFeed] deactivate];
}

- (IBAction)versionAction:(id)sender
{
    self.versionButton.hidden = YES;
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [[NSUserDefaults standardUserDefaults] setObject:version forKey:@"LastVersion"];
}
@end
