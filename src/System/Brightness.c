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

double GetDisplayBrightness(void)
{
    mach_port_t master_port;
    io_service_t serv = 0;
    float brightness = NAN;
    kern_return_t ret;

    ret = IOMasterPort(bootstrap_port, &master_port);
    if (KERN_SUCCESS != ret)
        goto exit;

    serv = IOServiceGetMatchingService(master_port,
        IOServiceMatching("IODisplayConnect")/* reference consumed by callee */);
    if (0 == serv)
    {
        ret = kIOReturnError;
        goto exit;
    }

    ret = IODisplayGetFloatParameter(serv, kNilOptions, CFSTR(kIODisplayBrightnessKey), &brightness);
    if (KERN_SUCCESS != ret)
        goto exit;

exit:
    if (0 != serv)
        IOObjectRelease(serv);

    return brightness;
}

bool SetDisplayBrightness(double brightness)
{
    mach_port_t master_port;
    io_service_t serv = 0;
    kern_return_t ret;

    ret = IOMasterPort(bootstrap_port, &master_port);
    if (KERN_SUCCESS != ret)
        goto exit;

    serv = IOServiceGetMatchingService(master_port,
        IOServiceMatching("IODisplayConnect")/* reference consumed by callee */);
    if (0 == serv)
    {
        ret = kIOReturnError;
        goto exit;
    }

    ret = IODisplaySetFloatParameter(serv, kNilOptions, CFSTR(kIODisplayBrightnessKey), brightness);
    if (KERN_SUCCESS != ret)
        goto exit;

exit:
    if (0 != serv)
        IOObjectRelease(serv);

    return KERN_SUCCESS == ret;
}
