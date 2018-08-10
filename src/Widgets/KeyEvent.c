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
#include "Carbon/Carbon.h"
//#include <CoreGraphics/CoreGraphics.h>
//#include <IOKit/hidsystem/ev_keymap.h>

bool PostKeyEvent(uint16_t keyCode, bool keyDown)
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
