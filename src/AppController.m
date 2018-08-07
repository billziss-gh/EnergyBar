/**
 * @file AppDelegate.m
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
#import "TouchBarPrivate.h"
#import "Widgets/ClockWidget.h"
#import "Widgets/ControlWidget.h"
#import "Widgets/KeyWidget.h"

@interface AppController () <NSApplicationDelegate, NSTouchBarProvider, NSTouchBarDelegate>
@property IBOutlet NSWindow *window;
@property IBOutlet NSTouchBar *touchBar;
@end

@implementation AppController

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    self.touchBar.customizationIdentifier = @"billziss.TouchBarDock";
    self.touchBar.defaultItemIdentifiers = [NSArray arrayWithObjects:
        @"ESC",
        NSTouchBarItemIdentifierFlexibleSpace,
        @"Control",
        @"Clock",
        nil];
    self.touchBar.customizationAllowedItemIdentifiers = [NSArray arrayWithObjects:
        @"ESC",
        NSTouchBarItemIdentifierFlexibleSpace,
        @"Control",
        @"Clock",
        nil];
    self.touchBar.delegate = self;

    DFRSystemModalShowsCloseBoxWhenFrontMost(FALSE);

    if ([NSTouchBar respondsToSelector:
        @selector(presentSystemModalTouchBar:placement:systemTrayItemIdentifier:)])
        [NSTouchBar
            presentSystemModalTouchBar:self.touchBar
            placement:1
            systemTrayItemIdentifier:nil];
    else if ([NSTouchBar respondsToSelector:
        @selector(presentSystemModalFunctionBar:placement:systemTrayItemIdentifier:)])
        [NSTouchBar
            presentSystemModalFunctionBar:self.touchBar
            placement:1
            systemTrayItemIdentifier:nil];
    else
    {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        alert.alertStyle = NSAlertStyleCritical;
        alert.messageText = @"Touch Bar API not found!";
        alert.informativeText = @"The TouchBarDock application will now exit.";
        [alert runModal];
        [NSApp terminate:nil];
    }
}


- (void)applicationWillTerminate:(NSNotification *)notification
{
}

- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar
    makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    if ([identifier isEqualToString:@"ESC"])
        return [[[KeyWidget alloc] initWithIdentifier:@"ESC"] autorelease];
    else if ([identifier isEqualToString:NSTouchBarItemIdentifierFlexibleSpace])
        return [[[NSTouchBarItem alloc] initWithIdentifier:NSTouchBarItemIdentifierFlexibleSpace] autorelease];
    else if ([identifier isEqualToString:@"Control"])
        return [[[ControlWidget alloc] initWithIdentifier:@"Control"] autorelease];
    else if ([identifier isEqualToString:@"Clock"])
        return [[[ClockWidget alloc] initWithIdentifier:@"Clock"] autorelease];
    else
        return nil;
}

- (IBAction)customizeTouchBar:(id)sender
{
    [NSApp toggleTouchBarCustomizationPalette:self];
}

@end
