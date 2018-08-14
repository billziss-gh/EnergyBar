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
#import "LoginItem.h"
#import "TouchBarController.h"

@interface NSView ()
- (void)_addKnownSubview:(NSView *)subview;
@end

@interface AppController () <NSApplicationDelegate>
@property (assign) IBOutlet TouchBarController *touchBarController;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *loginItemButton;
@end

@implementation AppController
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

    [[NSFileManager defaultManager]
        createDirectoryAtPath:[defaults objectForKey:@"defaultAppsFolder"]
        withIntermediateDirectories:YES
        attributes:nil
        error:nil];

    NSView *contentView = self.window.contentView;
    NSView *superView = contentView.superview;
    if ([superView respondsToSelector:@selector(_addKnownSubview:)])
        [superView _addKnownSubview:contentView];
    else
        [superView addSubview:contentView];

    NSApp.touchBar = self.touchBarController.touchBar;
    [self performSelector:@selector(presentTouchBar) withObject:nil afterDelay:0];

    self.loginItemButton.state = IsLoginItem([[NSBundle mainBundle] bundleURL]) ?
        NSControlStateValueOn : NSControlStateValueOff;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"mainWindowHidden"])
        [[NSApp.windows objectAtIndex:0] makeKeyAndOrderFront:nil];
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

- (IBAction)resetAppsFromDockAction:(id)sender
{
    NSString *defaultAppsFolder = [[NSUserDefaults standardUserDefaults]
        stringForKey:@"defaultAppsFolder"];

    NSArray *contents = nil;
    if (nil != defaultAppsFolder)
        contents = [[NSFileManager defaultManager]
            contentsOfDirectoryAtPath:defaultAppsFolder error:0];

    if (0 != contents.count)
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
        if (NSAlertFirstButtonReturn != resp)
            return;
    }
}

- (IBAction)showAppsFolderAction:(id)sender
{
    [[NSWorkspace sharedWorkspace]
        openFile:[[NSUserDefaults standardUserDefaults] objectForKey:@"defaultAppsFolder"]];
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

@interface StringToUrlTransformer : NSValueTransformer
@end

@implementation StringToUrlTransformer
+ (Class)transformedValueClass
{
    return [NSURL class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    return nil != value ? [NSURL fileURLWithPath:[value description]] : nil;
}

- (id)reverseTransformedValue:(id)value
{
    return [value path];
}
@end
