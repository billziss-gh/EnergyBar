/**
 * @file NSWorkspace+Finder.m
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

#import "NSWorkspace+Finder.h"
#import <pthread.h>
#import "FSNotify.h"

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

@implementation NSWorkspace (Finder)
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
    NSAppleScript *script = [[[NSAppleScript alloc]
        initWithSource:@"tell application \"Finder\"\nempty the trash\nend tell"] autorelease];
    return nil != [script executeAndReturnError:0];
}

- (BOOL)moveToTrash:(NSArray<NSURL *> *)urls
{
    BOOL res = NO;

    NSAppleEventDescriptor *finder = [NSAppleEventDescriptor
        descriptorWithBundleIdentifier:@"com.apple.finder"];
    NSAppleEventDescriptor *event = [NSAppleEventDescriptor
        appleEventWithEventClass:kAECoreSuite
        eventID:kAEDelete
        targetDescriptor:finder
        returnID:kAutoGenerateReturnID
        transactionID:kAnyTransactionID];
    NSAppleEventDescriptor *list = [NSAppleEventDescriptor listDescriptor];
    for (NSURL *url in urls)
    {
        NSAppleEventDescriptor *urldesc = [NSAppleEventDescriptor
            descriptorWithDescriptorType:typeFileURL
            data:[[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding]];
        [list insertDescriptor:urldesc atIndex:[list numberOfItems]];
    }
    [event setParamDescriptor:list forKeyword:keyDirectObject];
    NSError *error = nil;
    [event sendEventWithOptions:NSAppleEventSendNoReply timeout:kAEDefaultTimeout error:&error];

    res = nil == error;

    return res;
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
