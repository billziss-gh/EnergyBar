/**
 * @file AudioVolume.c
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

#include "AudioVolume.h"
#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioServices.h>
#include <pthread.h>

static pthread_once_t audio_dev_once = PTHREAD_ONCE_INIT;
static AudioDeviceID audio_dev = kAudioObjectUnknown;

static void audio_dev_initonce(void)
{
    AudioObjectPropertyAddress address =
    {
        .mSelector = kAudioHardwarePropertyDefaultOutputDevice,
        .mScope = kAudioObjectPropertyScopeGlobal,
        .mElement = kAudioObjectPropertyElementMaster,
    };
    AudioDeviceID device = kAudioObjectUnknown;
    UInt32 size = sizeof device;

    if (kAudioHardwareNoError !=
        AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, 0, &size, &device))
        return;

    audio_dev = device;
}

double GetAudioVolume(void)
{
    pthread_once(&audio_dev_once, audio_dev_initonce);
    if (kAudioObjectUnknown == audio_dev)
        return NAN;

    AudioObjectPropertyAddress address =
    {
        .mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
        .mScope = kAudioDevicePropertyScopeOutput,
        .mElement = kAudioObjectPropertyElementMaster,
    };
    Float32 volume = NAN;
    UInt32 size = sizeof volume;

    if (kAudioHardwareNoError !=
        AudioObjectGetPropertyData(audio_dev, &address, 0, 0, &size, &volume))
        return NAN;

    return volume;
}

bool SetAudioVolume(double volume0)
{
    pthread_once(&audio_dev_once, audio_dev_initonce);
    if (kAudioObjectUnknown == audio_dev)
        return false;

    AudioObjectPropertyAddress address =
    {
        .mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
        .mScope = kAudioDevicePropertyScopeOutput,
        .mElement = kAudioObjectPropertyElementMaster,
    };
    Float32 volume = volume0;

    if (kAudioHardwareNoError !=
        AudioObjectSetPropertyData(audio_dev, &address, 0, 0, sizeof volume, &volume))
        return false;

    return true;
}
