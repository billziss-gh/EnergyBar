/**
 * @file KeyEvent.h
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

#ifndef KEYEVENT_H_INCLUDED
#define KEYEVENT_H_INCLUDED

#include <stdint.h>

void PostKeyPress(uint16_t keyCode, uint32_t flags);
void PostAuxKeyPress(uint16_t auxKeyCode);

#endif
