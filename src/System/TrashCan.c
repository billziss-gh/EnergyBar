/**
 * @file TrashCan.c
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

#include "TrashCan.h"
#include <CoreServices/CoreServices.h>

bool OpenTrashCan(void)
{
    static const char finder[] = "com.apple.finder";
    static FourCharCode trash = kContainerTrashAliasType;
    AEDesc finderTarget = { .descriptorType = typeNull };
    AEDesc trashTarget = { .descriptorType = typeNull };
    AppleEvent event = { .descriptorType = typeNull };
    AEDesc container = { .descriptorType = typeNull };
    AEDesc specifier = { .descriptorType = typeNull };
    OSStatus status;
    bool res = false;

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
        false,
        &specifier);
    if (noErr != status)
        goto exit;

    status = AEPutParamDesc(&event, keyDirectObject, &specifier);
    if (noErr != status)
        goto exit;

    status = AESendMessage(&event, 0, kAENoReply, kAEDefaultTimeout);
    if (noErr != status)
        goto exit;

    res = true;

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
