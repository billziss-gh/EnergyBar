/**
 * @file Brightness.c
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

#include "Brightness.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/graphics/IOGraphicsLib.h>
#include <pthread.h>

static pthread_once_t disp_serv_once = PTHREAD_ONCE_INIT;
static io_connect_t disp_serv = 0;

static void disp_serv_initonce(void)
{
    mach_port_t master_port;
    kern_return_t ret;

    ret = IOMasterPort(bootstrap_port, &master_port);
    if (KERN_SUCCESS != ret)
        return;

    disp_serv = IOServiceGetMatchingService(master_port,
        IOServiceMatching("IODisplayConnect")/* ref consumed by IOServiceGetMatchingService */);
}

double GetDisplayBrightness(void)
{
    float brightness;
    kern_return_t ret;

    pthread_once(&disp_serv_once, disp_serv_initonce);
    if (0 == disp_serv)
        return NAN;

    ret = IODisplayGetFloatParameter(disp_serv, kNilOptions,
        CFSTR(kIODisplayBrightnessKey), &brightness);
    if (KERN_SUCCESS != ret)
        return NAN;

    return brightness;
}

bool SetDisplayBrightness(double brightness)
{
    kern_return_t ret;

    pthread_once(&disp_serv_once, disp_serv_initonce);
    if (0 == disp_serv)
        return false;

    ret = IODisplaySetFloatParameter(disp_serv, kNilOptions,
        CFSTR(kIODisplayBrightnessKey), brightness);
    if (KERN_SUCCESS != ret)
        return false;

    return true;
}
