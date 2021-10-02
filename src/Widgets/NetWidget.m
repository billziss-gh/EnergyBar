/**
 * @file NetWidget.m
 *
 * @copyright 2018 Simon Bennett
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import "NetWidget.h"
#import "ImageTitleView.h"

@interface NetWidgetView : ImageTitleView
@end

@implementation NetWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(64, NSViewNoIntrinsicMetric);
}
@end

@interface NetWidget () <CWEventDelegate>
@property (retain) CWWiFiClient *wfc;
@end

@implementation NetWidget

- (void)commonInit
{
    self.customizationLabel = @"WiFi Network";
    ImageTitleView *view = [[[NetWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    view.wantsLayer = YES;
    view.layer.cornerRadius = 8.0;
    view.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];
    view.imageSize = NSMakeSize(20, 20);
    view.titleFont = [NSFont systemFontOfSize:[NSFont
                                                   systemFontSizeForControlSize:NSControlSizeSmall]];
    view.titleLineBreakMode = NSLineBreakByTruncatingTail;
    view.subtitleFont = [NSFont systemFontOfSize:[NSFont
                                                  systemFontSizeForControlSize:NSControlSizeSmall]];
    view.subtitleLineBreakMode = NSLineBreakByTruncatingTail;
    self.view = view;
    
    self.wfc = [CWWiFiClient.sharedWiFiClient autorelease];
    if (self.wfc)
    {
        [self.wfc setDelegate:self];
        CWInterface *wif = self.wfc.interface;
        if (wif)
        {
            [self updateNetworkName:[wif ssid]];
        }
        [self.wfc startMonitoringEventWithType:CWEventTypeSSIDDidChange error:nil];
    }
}

- (void)dealloc
{
    if (self.wfc)
    {
        [self.wfc stopMonitoringEventWithType:CWEventTypeSSIDDidChange error:nil];
    }
    self.wfc = nil;
    [super dealloc];
}

- (void)ssidDidChangeForWiFiInterfaceWithName:(NSString *)interfaceName;
{
    if (self.wfc)
    {
        CWInterface *wif = [self.wfc interfaceWithName:interfaceName];
        if (wif)
        {
            [self updateNetworkName:[wif ssid]];
        }
    }
}

- (void)updateNetworkName:(NSString *)networkName
{
    [self performBlockOnMainThread:^
    {
        ImageTitleViewLayoutOptions layoutOptions = 0;
        layoutOptions |= ImageTitleViewLayoutOptionTitle;
        //layoutOptions |= ImageTitleViewLayoutOptionSubtitle;
    
        ImageTitleView *view = self.view;
        view.title = networkName?networkName:@"---";
        //view.subtitle = @"subtitle";
        view.layoutOptions = layoutOptions;
    }];
}

- (void)performBlockOnMainThread:(void (^)(void))block
{
    block = [block copy];
    [self
     performSelectorOnMainThread:@selector(performBlockOnMainThread_:)
     withObject:block
     waitUntilDone:NO];
    [block release];
}

- (void)performBlockOnMainThread_:(void (^)(void))block
{
    block();
}
@end
