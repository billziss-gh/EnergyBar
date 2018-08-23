/**
 * @file FSNotify.c
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

#include "FSNotify.h"
#include <CoreServices/CoreServices.h>

struct FSNotifyInfo
{
    void (*callback)(const char *, void *data);
    void *data;
};

static void FSNotifyCallback(ConstFSEventStreamRef stream, void *info0,
    size_t count, void *paths, const FSEventStreamEventFlags *flags, const FSEventStreamEventId *ids)
{
    struct FSNotifyInfo *info = info0;

    for (size_t i = 0; count > i; i++)
        info->callback(((const char **)paths)[i], info->data);
}

void *FSNotifyStart(const char *cpath, void (*callback)(const char *, void *), void *data)
{
    if (0 == cpath || 0 == callback)
        return 0;

    FSEventStreamRef res = 0;
    CFStringRef path = 0;
    CFArrayRef paths = 0;
    struct FSNotifyInfo *info = 0;
    FSEventStreamContext context = { 0 };
    FSEventStreamRef stream = 0;
    bool scheduled = false;

    path = CFStringCreateWithCString(0, cpath, kCFStringEncodingUTF8);
    if (0 == path)
        goto exit;

    paths = CFArrayCreate(0, (const void **)&path, 1, &kCFTypeArrayCallBacks);
    if (0 == paths)
        goto exit;

    info = malloc(sizeof *info);
    if (0 == info)
        goto exit;

    info->callback = callback;
    info->data = data;

    context.info = info;
    context.release = (void (*)(const void *))(free);

    stream = FSEventStreamCreate(0, FSNotifyCallback,
        &context, paths, kFSEventStreamEventIdSinceNow, 1.0, kFSEventStreamCreateFlagNoDefer);
    if (0 == stream)
        goto exit;

    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    scheduled = true;

    if (!FSEventStreamStart(stream))
        goto exit;

    res = stream;

exit:
    if (0 == res && scheduled)
        FSEventStreamInvalidate(stream);

    if (0 == res && 0 != stream)
        FSEventStreamRelease(stream);

    if (0 == res && 0 != info)
        free(info);

    if (0 != paths)
        CFRelease(paths);

    if (0 != path)
        CFRelease(path);

    return res;
}

void FSNotifyStop(void *stream)
{
    if (0 == stream)
        return;

    FSEventStreamStop(stream);
    FSEventStreamInvalidate(stream);
    FSEventStreamRelease(stream);
}
