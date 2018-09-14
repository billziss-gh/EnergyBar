/**
 * @file EdgeWindowController.h
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

#import <Cocoa/Cocoa.h>

@class EdgeWindowController;

@protocol EdgeWindowControllerDelegate <NSObject>
@optional
- (void)edgeWindowController:(EdgeWindowController *)controller
    mouseHoverAtPoint:(NSPoint)point;
- (void)edgeWindowController:(EdgeWindowController *)controller
    mouseClickAtPoint:(NSPoint)point;
- (NSDragOperation)edgeWindowController:(EdgeWindowController *)controller
    dragURLs:(NSArray *)urls atPoint:(NSPoint)point operation:(NSDragOperation)operation;
- (BOOL)edgeWindowController:(EdgeWindowController *)controller
    dropURLs:(NSArray *)urls atPoint:(NSPoint)point operation:(NSDragOperation)operation
    destination:(NSURL **)destination;
@end

@interface EdgeWindowController : NSWindowController
+ (id)controller;
@property (assign) id<EdgeWindowControllerDelegate> delegate;
@end
