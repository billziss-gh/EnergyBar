//
//  ControlTrayWidget.m
//  EnergyBar
//
//  Created by Max Zhao on 28/02/2019.
//  Copyright © 2019 Bill Zissimopoulos. All rights reserved.
//

#import "ControlTrayWidget.h"

@implementation ControlButtonWidget
{
    SEL longAction;
    id longTarget;
    SEL shortAction;
    id shortTarget;
}
- (void)commonInit
{
    [self setView: [NSButton buttonWithImage:[NSImage imageNamed:@"AppIcon"] target:self action:@selector(shortPressAction)]];
}

- (void)shortPressAction
{
    [shortTarget performSelector:shortAction withObject:self];
}

- (void)longPressAction:(id)sender
{
    [longTarget performSelector:longAction withObject:self];
}

- (void)setLongPress:(id)target action:(SEL)action
{
    longAction = action;
    longTarget = target;
}

- (void)setShortPress:(id)target action:(SEL)action
{
    shortAction = action;
    shortTarget = target;
}

@end

@implementation ControlTrayWidget
- (void)commonInit
{
    self.widget = [ControlButtonWidget alloc];
    [self.widget commonInit];
    [self.widget initWithIdentifier:@"EnergyBarControlButton"];
    [self addWidget:self.widget];
}

- (void)dealloc
{
    [self.widget dealloc];
    [super dealloc];
}
@end
