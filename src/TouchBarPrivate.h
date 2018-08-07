/**
 * @file TouchBarPrivate.h
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

#import <Cocoa/Cocoa.h>

void DFRElementSetControlStripPresenceForIdentifier(NSTouchBarItemIdentifier, BOOL);
void DFRSystemModalShowsCloseBoxWhenFrontMost(BOOL);

@interface NSTouchBar (Private)
/* macOS 10.13 */
+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar
    placement:(long long)placement
    systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier;
+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar
    systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier;
+ (void)dismissSystemModalFunctionBar:(NSTouchBar *)touchBar;
+ (void)minimizeSystemModalFunctionBar:(NSTouchBar *)touchBar;

/* macOS 10.14 */
+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar
    placement:(long long)placement
    systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier;
+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar
    systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier;
+ (void)dismissSystemModalTouchBar:(NSTouchBar *)touchBar;
+ (void)minimizeSystemModalTouchBar:(NSTouchBar *)touchBar;
@end

@interface NSTouchBarItem (Private)
+ (void)addSystemTrayItem:(NSTouchBarItem *)item;
+ (void)removeSystemTrayItem:(NSTouchBarItem *)item;
@end
