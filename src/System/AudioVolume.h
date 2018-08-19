/**
 * @file AudioVolume.h
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

#ifndef AUDIOVOLUME_H_INCLUDED
#define AUDIOVOLUME_H_INCLUDED

#include <stdbool.h>

double GetAudioVolume(void);
bool SetAudioVolume(double volume);

bool IsAudioMuted(void);
bool SetAudioMuted(bool mute);

#endif
