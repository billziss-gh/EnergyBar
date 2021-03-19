/**
 * @file NowPlayingWidget.h
 */


#import <Cocoa/Cocoa.h>
#import "CustomWidget.h"

@interface NowPlayingWidget : CustomMultiWidget
@property (getter=showsActiveAppOnTap, setter=setShowsActiveAppOnTap:) BOOL showsActiveAppOnTap;
@property (getter=showsTodoOnTap, setter=setShowsTodoOnTap:) BOOL showsTodoOnTap;
@property (getter=showsSmallWidget, setter=setShowsSmallWidget:) BOOL showsSmallWidget;
@property (getter=showsAlbumArt, setter=setShowsAlbumArt:) BOOL showsAlbumArt;
@property (getter=todoShowsEventsInterval, setter=todoSetShowsEventsInterval:)
    double todoShowsEventsInterval;
@property (getter=todoShowsReminders, setter=todoSetShowsReminders:) BOOL todoShowsReminders;
- (void)todoReset;
@end
