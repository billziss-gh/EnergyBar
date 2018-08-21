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
        @"EscKey",
        @"ActiveApp",
        @"Control",
        @"Clock",
        nil];

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
@end
