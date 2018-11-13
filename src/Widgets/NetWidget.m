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
#import "KeyEvent.h"

@interface NetWidgetLabel : NSTextField <CWEventDelegate>

@end

@implementation NetWidgetLabel
- (NSSize)intrinsicContentSize
{
    NSSize size = [super intrinsicContentSize];
    size.width = 64;
    return size;
}

- (void) setStringValue:(NSString *)aString
{
    NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:aString
                                                        attributes:@{}];
    // SPB Possibly useful for showing the connection state as a strike-out
    //[as addAttribute:NSStrikethroughStyleAttributeName value:(NSNumber *)kCFBooleanTrue range:NSMakeRange(0, [as length])];
    //[as addAttribute:NSStrikethroughColorAttributeName value:(NSColor *)[NSColor redColor] range:NSMakeRange(0, [as length])];
    //[as addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:5.0] range:NSMakeRange(0, as.length)];
    [as addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:12] range:NSMakeRange(0, as.length)];
    [self setAttributedStringValue:[as autorelease]];
}

- (void)ssidDidChangeForWiFiInterfaceWithName:(NSString *)interfaceName;
{
    CWWiFiClient *wfc = CWWiFiClient.sharedWiFiClient;
    if (wfc) {
        CWInterface *wif = [wfc interfaceWithName:interfaceName];
        if (wif) {
            NSString *ssid = [wif ssid];
            if (!ssid) {
                ssid = @"---";
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setStringValue:ssid];
            });
        }
    }
}
@end

@implementation NetWidget
- (void)commonInit
{
    NetWidgetLabel *textField = [ NetWidgetLabel labelWithString:@"---" ];
    [textField setAlignment:NSTextAlignmentCenter];
    [textField setTextColor:NSColor.lightGrayColor];
    self.view = textField;
    
    CWWiFiClient *wfc = CWWiFiClient.sharedWiFiClient;
    if (wfc) {
        [wfc setDelegate:textField];
        CWInterface *wif = wfc.interface;
        if (wif) {
            [textField ssidDidChangeForWiFiInterfaceWithName:wif.interfaceName];
        }
        [wfc startMonitoringEventWithType:CWEventTypeSSIDDidChange error:nil];
    }
}

- (void)dealloc
{
    // SPB TODO Clean up here
    CWWiFiClient *wfc = CWWiFiClient.sharedWiFiClient;
    if (wfc) {
        [wfc stopMonitoringEventWithType:CWEventTypeSSIDDidChange error:nil];
    }
    [super dealloc];
}
@end
