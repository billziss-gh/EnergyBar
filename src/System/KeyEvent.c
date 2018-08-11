/**
 * @file KeyEvent.c
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

#include "KeyEvent.h"
#include <CoreGraphics/CoreGraphics.h>
#include <pthread.h>

static bool PostKeyEvent(uint16_t keyCode, bool keyDown)
{
    CGEventRef event = CGEventCreateKeyboardEvent(0, keyCode, keyDown);
    if (0 != event)
    {
        CGEventPost(kCGHIDEventTap, event);
        CFRelease(event);
        return true;
    }
    return false;
}

void PostKeyPress(uint16_t keyCode)
{
    PostKeyEvent(keyCode, true);
    PostKeyEvent(keyCode, false);
}

static pthread_once_t hid_conn_once = PTHREAD_ONCE_INIT;
static io_connect_t hid_conn = 0;

static void hid_conn_initonce(void)
{
    mach_port_t master_port;
    io_service_t serv = 0;
    kern_return_t ret;

    ret = IOMasterPort(bootstrap_port, &master_port);
    if (KERN_SUCCESS != ret)
        goto exit;

    serv = IOServiceGetMatchingService(master_port,
        IOServiceMatching(kIOHIDSystemClass)/* reference consumed by callee */);
    if (0 == serv)
        goto exit;

    ret = IOServiceOpen(serv, mach_task_self(), kIOHIDParamConnectType, &hid_conn);
    if (KERN_SUCCESS != ret)
        goto exit;

exit:
    if (0 != serv)
        IOObjectRelease(serv);
}

void PostAuxKeyPress(uint16_t auxKeyCode)
{
    NXEventData event = { 0 };
    IOGPoint point = { 0 };
    kern_return_t ret;

    pthread_once(&hid_conn_once, hid_conn_initonce);
    if (0 == hid_conn)
        return;

    event.compound.subType = NX_SUBTYPE_AUX_CONTROL_BUTTONS;
    event.compound.misc.L[0] = (NX_KEYDOWN << 8) | (auxKeyCode << 16);
    ret = IOHIDPostEvent(hid_conn, NX_SYSDEFINED, point, &event, kNXEventDataVersion, 0, 0);
    if (KERN_SUCCESS != ret)
        return;

    event.compound.subType = NX_SUBTYPE_AUX_CONTROL_BUTTONS;
    event.compound.misc.L[0] = (NX_KEYUP << 8) | (auxKeyCode << 16);
    ret = IOHIDPostEvent(hid_conn, NX_SYSDEFINED, point, &event, kNXEventDataVersion, 0, 0);
    if (KERN_SUCCESS != ret)
        return;
}
