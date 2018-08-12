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
#import "TouchBarController.h"

@interface AppController () <NSApplicationDelegate>
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet TouchBarController *touchBarController;
@end

@implementation AppController
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSDictionary *defaults = [NSDictionary
        dictionaryWithContentsOfFile:[[NSBundle mainBundle]
        pathForResource:@"defaults"
        ofType:@"plist"]];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    NSApp.touchBar = self.touchBarController.touchBar;

    [self performSelector:@selector(presentTouchBar) withObject:nil afterDelay:0];
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
        alert.informativeText = @"The TouchBarDock application will now exit.";
        [alert runModal];
        [NSApp terminate:nil];
    }
}

- (IBAction)sourceLinkAction:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/billziss-gh"]];
}
@end
