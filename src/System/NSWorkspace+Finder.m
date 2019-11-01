/**
 * @file NSWorkspace+Finder.m
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

#import "NSWorkspace+Finder.h"
#import <pthread.h>
#import "FSNotify.h"

@implementation NSWorkspace (FileOperations)
- (BOOL)performEventID:(AEEventID)eventID forItemsAtURLs:(NSArray<NSURL *> *)urls toURL:(NSURL *)url
{
    NSAppleEventDescriptor *finder = [NSAppleEventDescriptor
        descriptorWithBundleIdentifier:@"com.apple.finder"];
    NSAppleEventDescriptor *event = [NSAppleEventDescriptor
        appleEventWithEventClass:kAECoreSuite
        eventID:eventID
        targetDescriptor:finder
        returnID:kAutoGenerateReturnID
        transactionID:kAnyTransactionID];

    NSAppleEventDescriptor *list = [NSAppleEventDescriptor listDescriptor];
    for (NSURL *url in urls)
    {
        NSAppleEventDescriptor *urldesc = [NSAppleEventDescriptor
            descriptorWithDescriptorType:typeFileURL
            data:[[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding]];
        [list insertDescriptor:urldesc atIndex:0];
    }
    [event setParamDescriptor:list forKeyword:keyDirectObject];

    if (nil != url)
    {
        NSAppleEventDescriptor *urldesc = [NSAppleEventDescriptor
            descriptorWithDescriptorType:typeFileURL
            data:[[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding]];
        [event setParamDescriptor:urldesc forKeyword:keyAEInsertHere];
    }

    NSError *error = nil;
    [event sendEventWithOptions:NSAppleEventSendNoReply timeout:kAEDefaultTimeout error:&error];

    return nil == error;
}

- (BOOL)copyItemsAtURLs:(NSArray<NSURL *> *)urls toURL:(NSURL *)url
{
    return [self performEventID:kAEClone forItemsAtURLs:urls toURL:url];
}

- (BOOL)moveItemsAtURLs:(NSArray<NSURL *> *)urls toURL:(NSURL *)url
{
    return [self performEventID:kAEMove forItemsAtURLs:urls toURL:url];
}

- (BOOL)aliasItemsAtURLs:(NSArray<NSURL *> *)urls toURL:(NSURL *)url
{
    NSAppleEventDescriptor *finder = [NSAppleEventDescriptor
        descriptorWithBundleIdentifier:@"com.apple.finder"];
    NSAppleEventDescriptor *event = [NSAppleEventDescriptor
        appleEventWithEventClass:kAECoreSuite
        eventID:kAECreateElement
        targetDescriptor:finder
        returnID:kAutoGenerateReturnID
        transactionID:kAnyTransactionID];

    NSAppleEventDescriptor *cls = [NSAppleEventDescriptor descriptorWithTypeCode:'alia'];
    [event setParamDescriptor:cls forKeyword:keyAEObjectClass];

    NSAppleEventDescriptor *list = [NSAppleEventDescriptor listDescriptor];
    for (NSURL *url in urls)
    {
        NSAppleEventDescriptor *urldesc = [NSAppleEventDescriptor
            descriptorWithDescriptorType:typeFileURL
            data:[[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding]];
        [list insertDescriptor:urldesc atIndex:0];
    }
    [event setParamDescriptor:list forKeyword:'to  '];

    NSAppleEventDescriptor *urldesc = [NSAppleEventDescriptor
        descriptorWithDescriptorType:typeFileURL
        data:[[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding]];
    [event setParamDescriptor:urldesc forKeyword:keyAEInsertHere];

    NSError *error = nil;
    [event sendEventWithOptions:NSAppleEventSendNoReply timeout:kAEDefaultTimeout error:&error];

    return nil == error;
}
@end

static pthread_once_t NSWorkspaceTrashFSNotify_once = PTHREAD_ONCE_INIT;
static void NSWorkspaceTrashFSNotify(const char *path, void *data);

static void NSWorkspaceTrashFSNotify_initonce(void)
{
    NSString *trash = [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
    FSNotifyStart([trash UTF8String], NSWorkspaceTrashFSNotify, 0);
}

static void NSWorkspaceTrashFSNotify(const char *path, void *data)
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"NSWorkspace+Trash"
        object:nil];
}

@implementation NSWorkspace (Trash)
- (NSString *)trashPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
}

- (BOOL)openTrash
{
    BOOL res = NO;

    NSAppleEventDescriptor *finder = [NSAppleEventDescriptor
        descriptorWithBundleIdentifier:@"com.apple.finder"];
    NSAppleEventDescriptor *event = [NSAppleEventDescriptor
        appleEventWithEventClass:kCoreEventClass
        eventID:kAEOpenDocuments
        targetDescriptor:finder
        returnID:kAutoGenerateReturnID
        transactionID:kAnyTransactionID];
    NSAppleEventDescriptor *specifier = [NSAppleEventDescriptor recordDescriptor];
    [specifier
        setDescriptor:[NSAppleEventDescriptor descriptorWithTypeCode:typeProperty]
        forKeyword:keyAEDesiredClass];
    [specifier
        setDescriptor:[NSAppleEventDescriptor nullDescriptor]
        forKeyword:keyAEContainer];
    [specifier
        setDescriptor:[NSAppleEventDescriptor descriptorWithEnumCode:formPropertyID]
        forKeyword:keyAEKeyForm];
    [specifier
        setDescriptor:[NSAppleEventDescriptor descriptorWithTypeCode:kContainerTrashAliasType]
        forKeyword:keyAEKeyData];
    specifier = [specifier coerceToDescriptorType:typeObjectSpecifier];
    [event setParamDescriptor:specifier forKeyword:keyDirectObject];
    NSError *error = nil;
    [event sendEventWithOptions:NSAppleEventSendNoReply timeout:kAEDefaultTimeout error:&error];

    res = nil == error &&
        [self
            launchAppWithBundleIdentifier:@"com.apple.finder"
            options:0
            additionalEventParamDescriptor:nil
            launchIdentifier:nil];

    return res;
}

- (BOOL)emptyTrash
{
    NSAppleEventDescriptor *finder = [NSAppleEventDescriptor
        descriptorWithBundleIdentifier:@"com.apple.finder"];
    NSAppleEventDescriptor *event = [NSAppleEventDescriptor
        appleEventWithEventClass:'fndr'
        eventID:kAEEmptyTrash
        targetDescriptor:finder
        returnID:kAutoGenerateReturnID
        transactionID:kAnyTransactionID];

    NSError *error = nil;
    [event sendEventWithOptions:NSAppleEventSendNoReply timeout:kAEDefaultTimeout error:&error];

    return nil == error;
}

- (BOOL)moveItemsToTrash:(NSArray<NSURL *> *)urls
{
    return [self performEventID:kAEDelete forItemsAtURLs:urls toURL:nil];
}

- (BOOL)isTrashFull
{
    BOOL res = NO;

    NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager]
        enumeratorAtPath:[self trashPath]];
    NSString *name;
    while (nil != (name = [direnum nextObject]))
    {
        if (![name isEqualToString:@".DS_Store"])
        {
            res = YES;
            break;
        }
    }

    return res;
}

- (void)addTrashObserver:(id)observer selector:(SEL)sel
{
    pthread_once(&NSWorkspaceTrashFSNotify_once, NSWorkspaceTrashFSNotify_initonce);

    [[NSNotificationCenter defaultCenter]
        addObserver:observer
        selector:sel
        name:@"NSWorkspace+Trash"
        object:nil];
}

- (void)removeTrashObserver:(id)observer
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:observer
        name:@"NSWorkspace+Trash"
        object:nil];
}
@end
