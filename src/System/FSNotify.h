/**
 * @file FSNotify.h
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

#ifndef FSNOTIFY_H_INCLUDED
#define FSNOTIFY_H_INCLUDED

void *FSNotifyStart(const char *cpath, void (*callback)(const char *, void *), void *data);
void FSNotifyStop(void *stream);

#endif
