/**
 * @file NSWorkspace+Trashcan.m
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

#import "NSWorkspace+Trashcan.h"
#import <pthread.h>
#import "FSNotify.h"

static pthread_once_t NSWorkspaceTrashcanFSNotify_once = PTHREAD_ONCE_INIT;
static void NSWorkspaceTrashcanFSNotify(const char *path, void *data);

static void NSWorkspaceTrashcanFSNotify_initonce(void)
{
    NSString *trash = [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
    FSNotifyStart([trash UTF8String], NSWorkspaceTrashcanFSNotify, 0);
}

static void NSWorkspaceTrashcanFSNotify(const char *path, void *data)
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"NSWorkspace+Trashcan"
        object:nil];
}

@implementation NSWorkspace (Trashcan)
- (BOOL)openTrashcan
{
    static const char finder[] = "com.apple.finder";
    static FourCharCode trash = kContainerTrashAliasType;
    AEDesc finderTarget = { .descriptorType = typeNull };
    AEDesc trashTarget = { .descriptorType = typeNull };
    AppleEvent event = { .descriptorType = typeNull };
    AEDesc container = { .descriptorType = typeNull };
    AEDesc specifier = { .descriptorType = typeNull };
    OSStatus status;
    BOOL res = NO;

    status = AECreateDesc(
        typeApplicationBundleID,
        &finder,
        sizeof finder,
        &finderTarget);
    if (noErr != status)
        goto exit;

    status = AECreateDesc(
        typeType,
        &trash,
        sizeof trash,
        &trashTarget);
    if (noErr != status)
        goto exit;

    status = AECreateAppleEvent(
        kCoreEventClass,
        kAEOpenDocuments,
        &finderTarget,
        kAutoGenerateReturnID,
        kAnyTransactionID,
        &event);
    if (noErr != status)
        goto exit;

    status = CreateObjSpecifier(
        typeProperty,
        &container,
        typeProperty,
        &trashTarget,
        NO,
        &specifier);
    if (noErr != status)
        goto exit;

    status = AEPutParamDesc(&event, keyDirectObject, &specifier);
    if (noErr != status)
        goto exit;

    status = AESendMessage(&event, 0, kAENoReply, kAEDefaultTimeout);
    if (noErr != status)
        goto exit;

    res = [self
        launchAppWithBundleIdentifier:[NSString stringWithUTF8String:finder]
        options:0
        additionalEventParamDescriptor:nil
        launchIdentifier:nil];

exit:
    if (typeNull != specifier.descriptorType)
        AEDisposeDesc(&specifier);

    if (typeNull != event.descriptorType)
        AEDisposeDesc(&event);

    if (typeNull != trashTarget.descriptorType)
        AEDisposeDesc(&trashTarget);

    if (typeNull != finderTarget.descriptorType)
        AEDisposeDesc(&finderTarget);

    return res;
}

- (BOOL)isTrashcanFull
{
    NSString *trash = [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
    NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager] enumeratorAtPath:trash];
    return nil != [direnum nextObject];
}

- (void)addTrashcanObserver:(id)observer selector:(SEL)sel
{
    pthread_once(&NSWorkspaceTrashcanFSNotify_once, NSWorkspaceTrashcanFSNotify_initonce);

    [[NSNotificationCenter defaultCenter]
        addObserver:observer
        selector:sel
        name:@"NSWorkspace+Trashcan"
        object:nil];
}

- (void)removeTrashcanObserver:(id)observer
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:observer
        name:@"NSWorkspace+Trashcan"
        object:nil];
}
@end
