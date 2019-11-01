/**
 * @file EdgeWindowController.m
 *
 * @copyright 2018-2019 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import "EdgeWindowController.h"

static const CGFloat ScreenWidthInTouchBarUnits = 1252;     /* don't ask! */
static const CGFloat TouchBarWidthInTouchBarUnits = 1085;

@interface EdgeWindowController () <NSWindowDelegate>
@end

@implementation EdgeWindowController
{
    NSTrackingRectTag _trackTag;
    NSTimer *_trackTimer;
    BOOL _trackSentHover;
}

+ (id)controller
{
    return [[[EdgeWindowController alloc] init] autorelease];
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
    window.releasedWhenClosed = YES;
    [window registerForDraggedTypes:[NSArray arrayWithObjects:
        NSPasteboardTypeURL,
        NSFilesPromisePboardType,
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
    [self snapToScreenEdge];
    [self.window orderFrontRegardless];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];

    [_trackTimer invalidate];
    [_trackTimer release];
    _trackTimer = nil;

    if (0 != _trackTag)
        [self.window.contentView removeTrackingRect:_trackTag];

    [self.window close];
    self.window = nil;

    [super dealloc];
}

- (void)snapToScreenEdge
{
    if (0 != _trackTag)
        [self.window.contentView removeTrackingRect:_trackTag];

    [self.window setFrame:[self screenEdgeRect] display:YES animate:NO];

    _trackTag = [self.window.contentView
        addTrackingRect:self.window.contentView.bounds
        owner:self
        userData:nil
        assumeInside:NO];
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
    [self snapToScreenEdge];
}

- (void)mouseEntered:(NSEvent *)event
{
    if ([self.delegate respondsToSelector:@selector(edgeWindowController:mouseHoverAtPoint:)])
    {
        [_trackTimer invalidate];
        [_trackTimer release];
        _trackTimer = [[NSTimer
            scheduledTimerWithTimeInterval:0.05
            target:self
            selector:@selector(mouseUpdated:)
            userInfo:nil
            repeats:YES] retain];
    }
}

- (void)mouseUpdated:(NSTimer *)timer
{
    if ([self.delegate respondsToSelector:@selector(edgeWindowController:mouseHoverAtPoint:)])
    {
        if (nil == _trackTimer)
            return;

        _trackSentHover = YES;
        NSPoint point = [self convertBaseToTouchBar:[self.window mouseLocationOutsideOfEventStream]];
        [self.delegate edgeWindowController:self mouseHoverAtPoint:point];
    }
}

- (void)mouseExited:(NSEvent *)event
{
    if ([self.delegate respondsToSelector:@selector(edgeWindowController:mouseHoverAtPoint:)])
    {
        if (nil == _trackTimer)
            return;

        [_trackTimer invalidate];
        [_trackTimer release];
        _trackTimer = nil;

        _trackSentHover = NO;
        NSPoint point = NSMakePoint(NAN, NAN);
        [self.delegate edgeWindowController:self mouseHoverAtPoint:point];
    }
}

- (void)mouseUp:(NSEvent *)event
{
    if ([self.delegate respondsToSelector:@selector(edgeWindowController:mouseClickAtPoint:)])
    {
        if (nil == _trackTimer)
            return;

        NSPoint point = [self convertBaseToTouchBar:[event locationInWindow]];
        [self.delegate edgeWindowController:self mouseClickAtPoint:point];
    }
}

- (BOOL)wantsPeriodicDraggingUpdates
{
    return YES;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    [_trackTimer invalidate];
    [_trackTimer release];
    _trackTimer = nil;

    if (_trackSentHover)
    {
        _trackSentHover = NO;
        NSPoint point = NSMakePoint(NAN, NAN);
        [self.delegate edgeWindowController:self mouseHoverAtPoint:point];
    }

    return [self draggingUpdated:sender];
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    if ([self.delegate respondsToSelector:@selector(edgeWindowController:dragURLs:atPoint:operation:)])
    {
        NSArray *urls;
        if ([sender.draggingPasteboard.types containsObject:NSFilesPromisePboardType])
            urls = [NSArray array];
        else
            urls = [sender.draggingPasteboard
                readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]]
                options:nil];
        NSPoint point = [self convertBaseToTouchBar:sender.draggingLocation];
        return [self.delegate
            edgeWindowController:self
            dragURLs:urls
            atPoint:point
            operation:sender.draggingSourceOperationMask];
    }

    return NSDragOperationNone;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    return [self draggingExited:sender];
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    if ([self.delegate respondsToSelector:@selector(edgeWindowController:dragURLs:atPoint:operation:)])
        [self.delegate
            edgeWindowController:self
            dragURLs:nil
            atPoint:NSZeroPoint
            operation:sender.draggingSourceOperationMask];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    if ([self.delegate
        respondsToSelector:@selector(edgeWindowController:dropURLs:atPoint:operation:destination:)])
    {
        NSURL *destination = nil, **pdestination = 0;
        NSArray *urls;
        if ([sender.draggingPasteboard.types containsObject:NSFilesPromisePboardType])
        {
            pdestination = &destination;
            urls = [NSArray array];
        }
        else
            urls = [sender.draggingPasteboard
                readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]]
                options:nil];
        NSPoint point = [self convertBaseToTouchBar:sender.draggingLocation];
        BOOL res = [self.delegate
            edgeWindowController:self
            dropURLs:urls
            atPoint:point
            operation:sender.draggingSourceOperationMask
            destination:pdestination];
        if (res && nil != destination)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [sender namesOfPromisedFilesDroppedAtDestination:destination];
#pragma clang diagnostic pop
        return res;
    }

    return NO;
}
@end
