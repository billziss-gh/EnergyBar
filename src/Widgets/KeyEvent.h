/**
 * @file KeyEvent.h
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

#ifndef KEYEVENT_H_INCLUDED
#define KEYEVENT_H_INCLUDED

#include <stdbool.h>
#include <stdint.h>

bool PostKeyEvent(uint16_t keyCode, bool keyDown);
void PostKeyPress(uint16_t keyCode);

#endif
