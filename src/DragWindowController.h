/**
 * @file DockWindowController.h
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

@class DragWindowController;

@protocol DragWindowControllerDelegate <NSObject>
@optional
- (void)dragWindowController:(DragWindowController *)controller
    mouseHoverAtPoint:(NSPoint)point;
- (void)dragWindowController:(DragWindowController *)controller
    mouseClickAtPoint:(NSPoint)point;
- (NSDragOperation)dragWindowController:(DragWindowController *)controller
    dragURLs:(NSArray *)urls atPoint:(NSPoint)point operation:(NSDragOperation)operation;
- (BOOL)dragWindowController:(DragWindowController *)controller
    dropURLs:(NSArray *)urls atPoint:(NSPoint)point operation:(NSDragOperation)operation
    destination:(NSURL **)destination;
@end

@interface DragWindowController : NSWindowController
+ (id)controller;
@property (assign) id<DragWindowControllerDelegate> delegate;
@end
