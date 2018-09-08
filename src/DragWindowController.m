/**
 * @file DockWindowController.m
 *
 * @copyright 2018 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import "DragWindowController.h"

static const CGFloat ScreenWidthInTouchBarUnits = 1252;     /* don't ask! */
static const CGFloat TouchBarWidthInTouchBarUnits = 1085;

@interface DragWindowController () <NSWindowDelegate>
@end

@implementation DragWindowController
+ (id)controller
{
    return [[[DragWindowController alloc] init] autorelease];
}

- (id)init
{
    NSWindow *window = [[[NSWindow alloc]
        initWithContentRect:NSZeroRect
        styleMask:NSWindowStyleMaskBorderless
        backing:NSBackingStoreBuffered
        defer:YES
        screen:nil] autorelease];
    window.alphaValue = 0;
    window.animationBehavior = NSWindowAnimationBehaviorNone;
    window.canHide = NO;
    window.collectionBehavior =
        NSWindowCollectionBehaviorCanJoinAllSpaces |
        NSWindowCollectionBehaviorStationary |
        NSWindowCollectionBehaviorIgnoresCycle |
        NSWindowCollectionBehaviorFullScreenAuxiliary;
    window.hasShadow = NO;
    window.hidesOnDeactivate = NO;
    window.ignoresMouseEvents = NO;
    window.level = NSMainMenuWindowLevel;
    window.opaque = NO;
    [window registerForDraggedTypes:[NSArray arrayWithObjects:
        NSPasteboardTypeURL,
        (NSString *)kPasteboardTypeFileURLPromise,
        nil]];
    //window.alphaValue = 1;
    //window.backgroundColor = [NSColor systemGreenColor];
    if (nil == window)
        return nil;

    self = [super initWithWindow:window];
    if (nil == self)
        return nil;

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(screenChanged:)
        name:NSApplicationDidChangeScreenParametersNotification
        object:nil];

    [self.window setDelegate:self];
    [self.window setFrame:[self screenEdgeRect] display:YES animate:NO];
    [self.window orderFrontRegardless];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];

    [super dealloc];
}

- (NSRect)screenEdgeRect
{
    NSRect frame = [[NSScreen screens] objectAtIndex:0].frame;
    return NSMakeRect(0, 0, frame.size.width, 1);
}

- (NSPoint)convertBaseToTouchBar:(NSPoint)point
{
    NSRect frame = [[NSScreen screens] objectAtIndex:0].frame;
    NSRect rect = [self.window convertRectToScreen:NSMakeRect(point.x, point.y, 0, 0)];
    point.x = rect.origin.x * ScreenWidthInTouchBarUnits / frame.size.width;
    point.x -= (ScreenWidthInTouchBarUnits - TouchBarWidthInTouchBarUnits) / 2;
    point.y = 30.0 / 2;

    return point;
}

- (void)screenChanged:(NSNotification *)notification
{
    [self.window setFrame:[self screenEdgeRect] display:YES animate:NO];
}

- (BOOL)wantsPeriodicDraggingUpdates
{
    return YES;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    if ([self.delegate respondsToSelector:@selector(dragWindowController:hoverURLs:atPoint:)])
    {
        NSArray *urls = [sender.draggingPasteboard
            readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]]
            options:nil];
        NSPoint point = [self convertBaseToTouchBar:sender.draggingLocation];
        return [self.delegate
            dragWindowController:self
            hoverURLs:urls
            atPoint:point] ? NSDragOperationEvery : NSDragOperationNone;
    }

    return NSDragOperationNone;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    return [self draggingExited:sender];
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    if ([self.delegate respondsToSelector:@selector(dragWindowController:hoverURLs:atPoint:)])
        [self.delegate
            dragWindowController:self
            hoverURLs:nil
            atPoint:NSZeroPoint];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    if ([self.delegate respondsToSelector:@selector(dragWindowController:acceptURLs:atPoint:)])
    {
        NSArray *urls = [sender.draggingPasteboard
            readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]]
            options:nil];
        NSPoint point = [self convertBaseToTouchBar:sender.draggingLocation];
        return [self.delegate
            dragWindowController:self
            acceptURLs:urls
            atPoint:point];
    }

    return NO;
}
@end
