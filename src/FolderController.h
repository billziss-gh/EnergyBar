/**
 * @file FolderController.h
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
#import "TouchBarController.h"

@class FolderController;

@protocol FolderControllerDelegate <NSObject>
@optional
- (void)folderController:(FolderController *)controller didSelectURL:(NSURL *)url;
- (void)folderController:(FolderController *)controller didClick:(NSString *)identifier;
@end

@interface FolderController : TouchBarController <NSScrubberDataSource, NSScrubberDelegate>
+ (id)controller;
@property (assign) id<FolderControllerDelegate> delegate;
@property (retain) NSURL *url;
@property (assign) BOOL includeDescendants;
@property (assign) NSURLResourceKey sortKey;
@property (assign) NSCellImagePosition imagePosition;
@property (assign) BOOL showsEmptyButton;
@property (assign) BOOL emptyButtonEnabled;
@end
