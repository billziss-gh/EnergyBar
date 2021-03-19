/**
 * @file NowPlaying.m
 *
 * @copyright 2018-2019 Bill Zissimopoulos
 */
/*
 * This file is part of EnergyBar.
 *
 * You can redistribute it and/or modify it under the terms of the GNU
 * General Public License version 3 as published by the Free Software
 * Foundation.
 */

#import "NowPlaying.h"

#define LastAppBundleIdentifier @"LastAppBundleIdentifier"

typedef void (^MRMediaRemoteGetNowPlayingInfoBlock)(NSDictionary *info);
typedef void (^MRMediaRemoteGetNowPlayingClientBlock)(id clientObj);
typedef void (^MRMediaRemoteGetNowPlayingApplicationIsPlayingBlock)(BOOL playing);

void MRMediaRemoteRegisterForNowPlayingNotifications(dispatch_queue_t queue);
void MRMediaRemoteGetNowPlayingClient(dispatch_queue_t queue,
    MRMediaRemoteGetNowPlayingClientBlock block);
void MRMediaRemoteGetNowPlayingInfo(dispatch_queue_t queue,
    MRMediaRemoteGetNowPlayingInfoBlock block);
void MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_queue_t queue,
    MRMediaRemoteGetNowPlayingApplicationIsPlayingBlock block);
NSString *MRNowPlayingClientGetBundleIdentifier(id clientObj);
NSString *MRNowPlayingClientGetParentAppBundleIdentifier(id clientObj);

extern NSString *kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification;
extern NSString *kMRMediaRemoteNowPlayingApplicationClientStateDidChange;
extern NSString *kMRNowPlayingPlaybackQueueChangedNotification;
extern NSString *kMRPlaybackQueueContentItemsChangedNotification;
extern NSString *kMRMediaRemoteNowPlayingApplicationDidChangeNotification;

extern NSString *kMRMediaRemoteNowPlayingInfoAlbum;
extern NSString *kMRMediaRemoteNowPlayingInfoArtist;
extern NSString *kMRMediaRemoteNowPlayingInfoTitle;
extern NSString *kMRMediaRemoteNowPlayingInfoArtworkData;

@implementation NowPlaying
+ (void)load
{
    MRMediaRemoteRegisterForNowPlayingNotifications(dispatch_get_main_queue());
}

+ (NowPlaying *)sharedInstance
{
    static NowPlaying *instance = 0;
    if (0 == instance)
        instance = [[NowPlaying alloc] init];
    return instance;
}

- (id)init
{
    self = [super init];
    if (nil == self)
        return nil;

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(appDidChange:)
        name:kMRMediaRemoteNowPlayingApplicationDidChangeNotification
        object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(infoDidChange:)
        name:kMRMediaRemoteNowPlayingApplicationClientStateDidChange
        object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(infoDidChange:)
        name:kMRNowPlayingPlaybackQueueChangedNotification
        object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(infoDidChange:)
        name:kMRPlaybackQueueContentItemsChangedNotification
        object:nil];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(playingDidChange:)
        name:kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification
        object:nil];

    [self updateApp];
    [self updateInfo];
    [self updateState];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];

    self.appBundleIdentifier = nil;
    self.appName = nil;
    self.appIcon = nil;
    self.album = nil;
    self.albumArt = nil;
    self.artist = nil;
    self.title = nil;

    [super dealloc];
}

- (void)updateApp
{
    MRMediaRemoteGetNowPlayingClient(dispatch_get_main_queue(),
        ^(id clientObj)
        {
            NSString *appBundleIdentifier = nil;
            NSString *appName = nil;
            NSImage *appIcon = nil;

            if (nil != clientObj)
            {
                appBundleIdentifier = MRNowPlayingClientGetBundleIdentifier(clientObj);
                if (nil == appBundleIdentifier)
                    appBundleIdentifier = MRNowPlayingClientGetParentAppBundleIdentifier(clientObj);
            }
            else
            {
                appBundleIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:LastAppBundleIdentifier];
            }
                
                
            if (nil != appBundleIdentifier)
            {
                NSString *path = [[NSWorkspace sharedWorkspace]
                    absolutePathForAppBundleWithIdentifier:appBundleIdentifier];
                if (nil != path)
                {
                    appName = [[NSFileManager defaultManager] displayNameAtPath:path];
                    appIcon = [[NSWorkspace sharedWorkspace] iconForFile:path];
                }
            }

            if (self.appBundleIdentifier != appBundleIdentifier ||
                self.appName != appName ||
                self.appIcon != appIcon)
            {
                self.appBundleIdentifier = appBundleIdentifier;
                self.appName = appName;
                self.appIcon = appIcon;

                [[NSNotificationCenter defaultCenter]
                    postNotificationName:NowPlayingInfoNotification
                    object:self];
              
                if (nil != self.appBundleIdentifier)
                {
                    [[NSUserDefaults standardUserDefaults] setObject:self.appBundleIdentifier forKey:LastAppBundleIdentifier];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
        });
}

- (void)updateInfo
{
    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(),
        ^(NSDictionary *info)
        {
            NSString *album = [info objectForKey:kMRMediaRemoteNowPlayingInfoAlbum];
            NSString *artist = [info objectForKey:kMRMediaRemoteNowPlayingInfoArtist];
            NSString *title = [info objectForKey:kMRMediaRemoteNowPlayingInfoTitle];
            NSData *artworkData = [info objectForKey:kMRMediaRemoteNowPlayingInfoArtworkData];
        
        NSImage *albumart = nil;
        if (nil != artworkData && ![artworkData isEqual:[NSNull null]])
        {
            albumart = [[NSImage alloc] initWithData:artworkData];
        }
        
            if (self.album != album || self.artist != artist || self.title != title || self.albumArt != albumart)
            {
                self.album = album;
                self.artist = artist;
                self.title = title;
                self.albumArt = albumart;

                [[NSNotificationCenter defaultCenter]
                    postNotificationName:NowPlayingInfoNotification
                    object:self];
            }
        });
}

- (void)updateState
{
    MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_get_main_queue(),
        ^(BOOL playing)
        {
            if (self.playing != playing)
            {
                self.playing = playing;

                [[NSNotificationCenter defaultCenter]
                    postNotificationName:NowPlayingStateNotification
                    object:self];
            }
        });
}

- (void)appDidChange:(NSNotification *)notification
{
    [self updateApp];
}

- (void)infoDidChange:(NSNotification *)notification
{
    /*
     The delay is necessary for album art to update correctly.
     Potentially, one can experiment with placing another [self updateInfo] before the delay to repeat this action, but this results in some wonky icon changes.
     */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(50 * NSEC_PER_MSEC)), dispatch_get_main_queue(),
       ^{
        [self updateInfo];
        });
}

- (void)playingDidChange:(NSNotification *)notification
{
    [self updateState];
}
@end

NSString *NowPlayingInfoNotification = @"NowPlayingInfo";
NSString *NowPlayingStateNotification = @"NowPlayingState";
