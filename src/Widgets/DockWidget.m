/**
 * @file DockWidget.m
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

#import "DockWidget.h"

@interface DockWidget () <NSScrubberDataSource, NSScrubberFlowLayoutDelegate>
@end

@implementation DockWidget
- (void)commonInit
{
    self.customizationLabel = @"Dock";

    NSScrubberFlowLayout *layout = [[[NSScrubberFlowLayout alloc] init] autorelease];
    layout.itemSize = NSMakeSize(50, 30);

    NSScrubber *scrubber = [[[NSScrubber alloc] initWithFrame:NSMakeRect(0, 0, 200, 30)] autorelease];
    scrubber.dataSource = self;
    scrubber.delegate = self;
    scrubber.mode = NSScrubberModeFixed;
    scrubber.continuous = NO;
    scrubber.itemAlignment = NSScrubberAlignmentNone;
    scrubber.scrubberLayout = layout;

    self.view = scrubber;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)viewWillAppear
{
}

- (void)viewWillDisappear
{
}

- (NSInteger)numberOfItemsForScrubber:(NSScrubber *)scrubber
{
    return 10;
}

- (NSScrubberItemView *)scrubber:(NSScrubber *)scrubber viewForItemAtIndex:(NSInteger)index
{
    NSSize itemSize = ((NSScrubberFlowLayout *)scrubber.scrubberLayout).itemSize;
    NSScrubberImageItemView *view = [[[NSScrubberImageItemView alloc]
        initWithFrame:NSMakeRect(0, 0, itemSize.width, itemSize.height)] autorelease];
    view.image = [NSImage imageNamed:@"BrightnessDown"];
    return view;
}
@end
