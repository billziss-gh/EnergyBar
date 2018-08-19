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

    if (kAudioHardwareNoError !=
        AudioObjectGetPropertyData(audio_dev, &address, 0, 0, &size, &mute))
        return false;

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

    if (kAudioHardwareNoError !=
        AudioObjectSetPropertyData(audio_dev, &address, 0, 0, sizeof mute, &mute))
        return false;

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

    /* NOTE:
     * It is not clear if AudioObjectAddPropertyListener / AudioObjectRemovePropertyListener
     * identify listeners using both the listener proc and its data. If both are used, then
     * AddAudioMutedListener / RemoveAudioMutedListener may be used multiple times. Otherwise
     * there can only be one outstanding listener.
     */
    if (kAudioHardwareNoError !=
        AudioObjectAddPropertyListener(audio_dev, &address, AudioMutedListener, listener))
        return false;

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

    /* NOTE:
     * It is not clear if AudioObjectAddPropertyListener / AudioObjectRemovePropertyListener
     * identify listeners using both the listener proc and its data. If both are used, then
     * AddAudioMutedListener / RemoveAudioMutedListener may be used multiple times. Otherwise
     * there can only be one outstanding listener.
     */
    if (kAudioHardwareNoError !=
        AudioObjectRemovePropertyListener(audio_dev, &address, AudioMutedListener, listener))
        return false;

    return true;
}
