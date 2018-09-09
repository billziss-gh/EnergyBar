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
#include <CoreGraphics/CoreGraphics.h>
#include <pthread.h>
#include "Log.h"

static io_service_t DisplayIOServicePort(CGDirectDisplayID display)
{
    io_service_t disp_serv;

    if (0 == display)
        display = CGMainDisplayID();

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    disp_serv = CGDisplayIOServicePort(display);
#pragma clang diagnostic pop
    if (0 == disp_serv)
        LOG("CGDisplayIOServicePort = %u", (unsigned)disp_serv);

    return disp_serv;
}

double GetDisplayBrightness(uint32_t display)
{
    io_service_t disp_serv;
    float brightness;
    kern_return_t ret;

    disp_serv = DisplayIOServicePort(display);
    if (0 == disp_serv)
        return NAN;

    ret = IODisplayGetFloatParameter(disp_serv, kNilOptions,
        CFSTR(kIODisplayBrightnessKey), &brightness);
    if (KERN_SUCCESS != ret)
    {
        LOG("IODisplayGetFloatParameter = %d", ret);
        return NAN;
    }

    return brightness;
}

bool SetDisplayBrightness(uint32_t display, double brightness)
{
    io_service_t disp_serv;
    kern_return_t ret;

    disp_serv = DisplayIOServicePort(display);
    if (0 == disp_serv)
        return NAN;

    ret = IODisplaySetFloatParameter(disp_serv, kNilOptions,
        CFSTR(kIODisplayBrightnessKey), brightness);
    if (KERN_SUCCESS != ret)
    {
        LOG("IODisplaySetFloatParameter = %d", ret);
        return false;
    }

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
