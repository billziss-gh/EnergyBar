/**
 * @file Brightness.c
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

#include "Brightness.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/graphics/IOGraphicsLib.h>
#include <pthread.h>

static pthread_once_t disp_serv_once = PTHREAD_ONCE_INIT;
static io_service_t disp_serv = 0;

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

static pthread_once_t lmu_serv_once = PTHREAD_ONCE_INIT;
static io_connect_t lmu_serv = 0;

/*
 * The ioreg utility shows this as the max value set by macOS when using the keyboard
 * brightness keys. Note that the range is non-linear but we use it as if it is.
 */
static const double MaxKeyboardBrightness = 342;

static void lmu_serv_initonce(void)
{
    mach_port_t master_port;
    kern_return_t ret;

    ret = IOMasterPort(bootstrap_port, &master_port);
    if (KERN_SUCCESS != ret)
        return;

    lmu_serv = IOServiceGetMatchingService(master_port,
        IOServiceMatching("AppleHIDKeyboardEventDriverV2")/* ref consumed by IOServiceGetMatchingService */);
}

double GetKeyboardBrightness(void)
{
    double brightness = NAN;
    CFTypeRef obj = 0;

    pthread_once(&lmu_serv_once, lmu_serv_initonce);
    if (0 == lmu_serv)
        goto exit;

    obj = IORegistryEntryCreateCFProperty(lmu_serv, CFSTR("KeyboardBacklightBrightness"), 0, 0);
    if (0 == obj)
        goto exit;

    if (CFGetTypeID(obj) != CFNumberGetTypeID())
        goto exit;

    if (!CFNumberGetValue(obj, kCFNumberDoubleType, &brightness))
        goto exit;

    if (brightness > MaxKeyboardBrightness)
        brightness = MaxKeyboardBrightness;
    brightness /= MaxKeyboardBrightness;

exit:
    if (0 != obj)
        CFRelease(obj);

    return brightness;
}

bool SetKeyboardBrightness(double brightness)
{
    CFTypeRef obj = 0;
    kern_return_t ret;
    bool res = false;

    pthread_once(&lmu_serv_once, lmu_serv_initonce);
    if (0 == lmu_serv)
        goto exit;

    brightness *= MaxKeyboardBrightness;
    if (brightness > MaxKeyboardBrightness)
        brightness = MaxKeyboardBrightness;

    obj = CFNumberCreate(0, kCFNumberDoubleType, &brightness);
    if (0 == obj)
        goto exit;

    ret = IORegistryEntrySetCFProperty(lmu_serv, CFSTR("KeyboardBacklightBrightness"), obj);
    if (KERN_SUCCESS != ret)
        goto exit;

    res = true;

exit:
    if (0 != obj)
        CFRelease(obj);

    return res;
}
