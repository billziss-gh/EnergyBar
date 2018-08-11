/**
 * @file Brightness.h
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

#ifndef BRIGHTNESS_H_INCLUDED
#define BRIGHTNESS_H_INCLUDED

#include <stdbool.h>

double GetDisplayBrightness(void);
bool SetDisplayBrightness(double brightness);

double GetKeyboardBrightness(void);
bool SetKeyboardBrightness(double brightness);

#endif
