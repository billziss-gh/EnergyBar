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

@interface TouchBarController () <NSTouchBarDelegate>
@end

@implementation TouchBarController
{
    NSTouchBar *_touchBar;
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
    [_touchBar release];

    [super dealloc];
}

- (BOOL)present
{
    return [self presentWithPlacement:1];
}

- (BOOL)presentWithPlacement:(NSInteger)placement
{
    if ([NSTouchBar respondsToSelector:
        @selector(presentSystemModalTouchBar:placement:systemTrayItemIdentifier:)])
    {
        [NSTouchBar
            presentSystemModalTouchBar:_touchBar
            placement:1
            systemTrayItemIdentifier:nil];
        return YES;
    }
    else if ([NSTouchBar respondsToSelector:
        @selector(presentSystemModalFunctionBar:placement:systemTrayItemIdentifier:)])
    {
        [NSTouchBar
            presentSystemModalFunctionBar:_touchBar
            placement:1
            systemTrayItemIdentifier:nil];
        return YES;
    }
    else
        return NO;
}

- (void)dismiss
{
    if ([NSTouchBar respondsToSelector:
        @selector(dismissSystemModalTouchBar:)])
    {
        [NSTouchBar
            dismissSystemModalTouchBar:_touchBar];
    }
    else if ([NSTouchBar respondsToSelector:
        @selector(dismissSystemModalFunctionBar:)])
    {
        [NSTouchBar
            dismissSystemModalFunctionBar:_touchBar];
    }
}

- (void)customize
{
    [NSApp toggleTouchBarCustomizationPalette:self];
}

- (NSTouchBar *)getTouchBar
{
    return _touchBar;
}

- (void)setTouchBar:(NSTouchBar *)touchBar
{
    [_touchBar release];
    _touchBar = [touchBar retain];
    _touchBar.delegate = self;
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
