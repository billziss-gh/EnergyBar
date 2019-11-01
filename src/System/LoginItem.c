/**
 * @file LoginItem.c
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

#include "LoginItem.h"
#include <CoreServices/CoreServices.h>

#pragma clang diagnostic ignored "-Wdeprecated"

static LSSharedFileListItemRef GetLoginItem(CFURLRef *url, LSSharedFileListRef *plist)
{
    LSSharedFileListRef list = 0;
    CFArrayRef array = 0;
    LSSharedFileListItemRef res = 0;

    list = LSSharedFileListCreate(0, kLSSharedFileListSessionLoginItems, 0);
    if (0 == list)
        goto exit;

    array = LSSharedFileListCopySnapshot(list, 0);
    if (0 == array)
        goto exit;

    for (CFIndex i = 0, n = CFArrayGetCount(array); n > i; i++)
    {
        LSSharedFileListItemRef item = (void *)CFArrayGetValueAtIndex(array, i);

        CFURLRef itemUrl = LSSharedFileListItemCopyResolvedURL(item,
            kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes, 0);
        if (0 == itemUrl)
            continue;

        if (CFEqual(itemUrl, url))
        {
            CFRelease(itemUrl);
            CFRetain(item);
            res = item;
            break;
        }

        CFRelease(itemUrl);
    }

exit:
    if (0 != plist)
        *plist = list;
    else if (0 != list)
        CFRelease(list);

    if (0 != array)
        CFRelease(array);

    return res;
}

bool IsLoginItem(void *cfurl)
{
    LSSharedFileListItemRef item = GetLoginItem(cfurl, 0);
    if (0 == item)
        return false;

    CFRelease(item);
    return true;
}

void SetLoginItem(void *cfurl, bool value)
{
    LSSharedFileListRef list = 0;
    LSSharedFileListItemRef item = GetLoginItem(cfurl, &list);

    if (0 == item && value)
        LSSharedFileListInsertItemURL(list, kLSSharedFileListItemLast, 0, 0, cfurl, 0, 0);
    else if (0 != item && !value)
        LSSharedFileListItemRemove(list, item);

    if (0 != item)
        CFRelease(item);

    if (0 != list)
        CFRelease(list);
}
