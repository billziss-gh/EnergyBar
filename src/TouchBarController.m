/**
 * @file TouchBarController.m
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

#import "TouchBarController.h"
#import "TouchBarPrivate.h"

@implementation TouchBarController
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
    self.touchBar = nil;

    [super dealloc];
}

- (BOOL)present
{
    return [self presentWithPlacement:1];
}

- (BOOL)presentWithPlacement:(NSInteger)placement
{
    if ([NSTouchBar respondsToSelector:
        @selector(presentSystemModalFunctionBar:placement:systemTrayItemIdentifier:)])
    {
        [NSTouchBar
            presentSystemModalFunctionBar:self.touchBar
            placement:placement
            systemTrayItemIdentifier:nil];
        return YES;
    }
    else if ([NSTouchBar respondsToSelector:
        @selector(presentSystemModalTouchBar:placement:systemTrayItemIdentifier:)])
    {
        [NSTouchBar
            presentSystemModalTouchBar:self.touchBar
            placement:placement
            systemTrayItemIdentifier:nil];
        return YES;
    }
    else
        return NO;
}

- (void)dismiss
{
    if ([NSTouchBar respondsToSelector:
        @selector(dismissSystemModalFunctionBar:)])
    {
        [NSTouchBar
            dismissSystemModalFunctionBar:self.touchBar];
    }
    else if ([NSTouchBar respondsToSelector:
        @selector(dismissSystemModalTouchBar:)])
    {
        [NSTouchBar
            dismissSystemModalTouchBar:self.touchBar];
    }
}

- (IBAction)customize:(id)sender
{
    [NSApp toggleTouchBarCustomizationPalette:self];
}

- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar
    makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    NSTouchBarItem *item = [_items objectForKey:identifier];
    if (nil == item)
    {
        Class widgetClass = NSClassFromString([identifier stringByAppendingString:@"Widget"]);
        item = [[[widgetClass alloc] initWithIdentifier:identifier] autorelease];
        [_items setObject:item forKey:identifier];
    }
    return item;
}
@end
