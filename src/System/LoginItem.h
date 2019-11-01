/**
 * @file LoginItem.h
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

#ifndef LOGINITEM_H_INCLUDED
#define LOGINITEM_H_INCLUDED

#include <stdbool.h>

bool IsLoginItem(void *cfurl);
void SetLoginItem(void *cfurl, bool value);

#endif
