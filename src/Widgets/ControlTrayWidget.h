//
//  ControlTrayWidget.h
//  EnergyBar
//
//  Created by Max Zhao on 28/02/2019.
//  Copyright © 2019 Bill Zissimopoulos. All rights reserved.
//

#import "CustomWidget.h"

@interface ControlButtonWidget : CustomWidget
- (void)longPressAction:(id)sender;
- (void)setLongPress:(id)target action:(SEL)action;
@end

@interface ControlTrayWidget : CustomMultiWidget
@property (assign) ControlButtonWidget *widget;
@end
