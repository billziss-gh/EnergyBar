/**
 * @file Log.h
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

#ifndef LOG_H_INCLUDED
#define LOG_H_INCLUDED

#include <os/log.h>

#define LOG(format, ...)                os_log(OS_LOG_DEFAULT, "%s: " format, __func__, __VA_ARGS__)

#endif
