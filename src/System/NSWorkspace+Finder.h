/**
 * @file NSWorkspace+Finder.h
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

@interface NSWorkspace (FileOperations)
- (BOOL)copyItemsAtURLs:(NSArray<NSURL *> *)urls toURL:(NSURL *)url;
- (BOOL)moveItemsAtURLs:(NSArray<NSURL *> *)urls toURL:(NSURL *)url;
- (BOOL)aliasItemsAtURLs:(NSArray<NSURL *> *)urls toURL:(NSURL *)url;
@end

@interface NSWorkspace (Trash)
- (NSString *)trashPath;
- (BOOL)openTrash;
- (BOOL)emptyTrash;
- (BOOL)moveItemsToTrash:(NSArray<NSURL *> *)urls;
- (BOOL)isTrashFull;
- (void)addTrashObserver:(id)observer selector:(SEL)sel;
- (void)removeTrashObserver:(id)observer;
@end
