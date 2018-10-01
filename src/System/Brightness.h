/**
 * @file Brightness.h
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

#ifndef BRIGHTNESS_H_INCLUDED
#define BRIGHTNESS_H_INCLUDED

#include <stdbool.h>
#include <stdint.h>

double GetDisplayBrightness(uint32_t display);
bool SetDisplayBrightness(uint32_t display, double brightness);

#if 0
double GetKeyboardBrightness(void);
bool SetKeyboardBrightness(double brightness);
#endif

#endif
