/**
 * @file AudioVolume.c
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

#include "AudioVolume.h"
#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioServices.h>
#include <pthread.h>
#include "Log.h"

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
    OSStatus status;

    status = AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, 0, &size, &device);
    if (kAudioHardwareNoError != status)
    {
        LOG("AudioObjectGetPropertyData = %d", status);
        return;
    }

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
    OSStatus status;

    status = AudioObjectGetPropertyData(audio_dev, &address, 0, 0, &size, &volume);
    if (kAudioHardwareNoError != status)
    {
        LOG("AudioObjectGetPropertyData = %d", status);
        return NAN;
    }

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
    OSStatus status;

    status = AudioObjectSetPropertyData(audio_dev, &address, 0, 0, sizeof volume, &volume);
    if (kAudioHardwareNoError != status)
    {
        LOG("AudioObjectSetPropertyData = %d", status);
        return false;
    }

    return true;
}

bool IsAudioMuted(void)
{
    pthread_once(&audio_dev_once, audio_dev_initonce);
    if (kAudioObjectUnknown == audio_dev)
        return NAN;

    AudioObjectPropertyAddress address =
    {
        .mSelector = kAudioDevicePropertyMute,
        .mScope = kAudioDevicePropertyScopeOutput,
        .mElement = kAudioObjectPropertyElementMaster,
    };
    UInt32 mute = 0;
    UInt32 size = sizeof mute;
    OSStatus status;

    status = AudioObjectGetPropertyData(audio_dev, &address, 0, 0, &size, &mute);
    if (kAudioHardwareNoError != status)
    {
        LOG("AudioObjectGetPropertyData = %d", status);
        return false;
    }

    return !!mute;
}

bool SetAudioMuted(bool mute0)
{
    pthread_once(&audio_dev_once, audio_dev_initonce);
    if (kAudioObjectUnknown == audio_dev)
        return false;

    AudioObjectPropertyAddress address =
    {
        .mSelector = kAudioDevicePropertyMute,
        .mScope = kAudioDevicePropertyScopeOutput,
        .mElement = kAudioObjectPropertyElementMaster,
    };
    UInt32 mute = !!mute0;
    OSStatus status;

    status = AudioObjectSetPropertyData(audio_dev, &address, 0, 0, sizeof mute, &mute);
    if (kAudioHardwareNoError != status)
    {
        LOG("AudioObjectSetPropertyData = %d", status);
        return false;
    }

    return true;
}

static OSStatus AudioMutedListener(
    AudioObjectID device,
    UInt32 count,
    const AudioObjectPropertyAddress* addresses,
    void *data)
{
    struct AudioPropertyListener *listener = data;
    listener->code(listener->data);
    return kAudioHardwareNoError;
}

bool AddAudioMutedListener(struct AudioPropertyListener *listener)
{
    pthread_once(&audio_dev_once, audio_dev_initonce);
    if (kAudioObjectUnknown == audio_dev)
        return false;

    AudioObjectPropertyAddress address =
    {
        .mSelector = kAudioDevicePropertyMute,
        .mScope = kAudioDevicePropertyScopeOutput,
        .mElement = kAudioObjectPropertyElementMaster,
    };
    OSStatus status;

    /* NOTE:
     * It is not clear if AudioObjectAddPropertyListener / AudioObjectRemovePropertyListener
     * identify listeners using both the listener proc and its data. If both are used, then
     * AddAudioMutedListener / RemoveAudioMutedListener may be used multiple times. Otherwise
     * there can only be one outstanding listener.
     */
    status = AudioObjectAddPropertyListener(audio_dev, &address, AudioMutedListener, listener);
    if (kAudioHardwareNoError != status)
    {
        LOG("AudioObjectAddPropertyListener = %d", status);
        return false;
    }

    return true;
}

bool RemoveAudioMutedListener(struct AudioPropertyListener *listener)
{
    pthread_once(&audio_dev_once, audio_dev_initonce);
    if (kAudioObjectUnknown == audio_dev)
        return false;

    AudioObjectPropertyAddress address =
    {
        .mSelector = kAudioDevicePropertyMute,
        .mScope = kAudioDevicePropertyScopeOutput,
        .mElement = kAudioObjectPropertyElementMaster,
    };
    OSStatus status;

    /* NOTE:
     * It is not clear if AudioObjectAddPropertyListener / AudioObjectRemovePropertyListener
     * identify listeners using both the listener proc and its data. If both are used, then
     * AddAudioMutedListener / RemoveAudioMutedListener may be used multiple times. Otherwise
     * there can only be one outstanding listener.
     */
    status = AudioObjectRemovePropertyListener(audio_dev, &address, AudioMutedListener, listener);
    if (kAudioHardwareNoError != status)
    {
        LOG("AudioObjectRemovePropertyListener = %d", status);
        return false;
    }

    return true;
}
