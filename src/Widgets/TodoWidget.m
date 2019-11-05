/**
 * @file TodoWidget.m
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

#import "TodoWidget.h"
#import "ImageTitleView.h"
#import <EventKit/EventKit.h>
#include <pthread.h>

@interface TodoWidgetView : ImageTitleView
@end

@implementation TodoWidgetView
- (NSSize)intrinsicContentSize
{
    return NSMakeSize(130, NSViewNoIntrinsicMetric);
}
@end

@interface TodoWidget ()
@property (copy) NSString *calendarAppIdentifier;
@property (copy) NSString *calendarIdentifier;
@property (copy) NSString *calendarItemIdentifier;
@end

@implementation TodoWidget
{
    BOOL _viewAppears;
}

static EKEventStore *eventStore;

- (void)commonInit
{
    self.customizationLabel = @"TODO";

    ImageTitleView *imageTitleView = [[[TodoWidgetView alloc] initWithFrame:NSZeroRect] autorelease];
    imageTitleView.wantsLayer = YES;
    imageTitleView.layer.cornerRadius = 8.0;
    imageTitleView.layer.backgroundColor = [[NSColor colorWithWhite:0.0 alpha:0.5] CGColor];
    imageTitleView.imageSize = NSMakeSize(16, 16);
    imageTitleView.titleFont = [NSFont systemFontOfSize:[NSFont
        systemFontSizeForControlSize:NSControlSizeSmall]];
    imageTitleView.titleLineBreakMode = NSLineBreakByWordWrapping;
    imageTitleView.layoutOptions = ImageTitleViewLayoutOptionTitle;
    imageTitleView.title = @"--";
    self.view = imageTitleView;

    NSPressGestureRecognizer *longPressRecognizer = [[[NSPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(longPressAction_:)] autorelease];
    longPressRecognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    longPressRecognizer.minimumPressDuration = LongPressDuration;
    [self.view addGestureRecognizer:longPressRecognizer];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];

    self.calendarAppIdentifier = nil;
    self.calendarIdentifier = nil;
    self.calendarItemIdentifier = nil;

    [super dealloc];
}

- (void)viewWillAppear
{
    _viewAppears = YES;

    [self resetWithNil];

    if (nil == eventStore)
        eventStore = [[EKEventStore alloc] init];

    if (0 < self.showsEventsInterval)
    {
        [eventStore
            requestAccessToEntityType:EKEntityTypeEvent
            completion:^(BOOL granted1, NSError *error)
            {
                if (self.showsReminders)
                {
                    [eventStore
                        requestAccessToEntityType:EKEntityTypeReminder
                        completion:^(BOOL granted2, NSError *error)
                        {
                            if (granted1 || granted2)
                                [self reset];
                        }];
                }
                else
                    [self reset];
            }];
    }
    else if (self.showsReminders)
    {
        [eventStore
            requestAccessToEntityType:EKEntityTypeReminder
            completion:^(BOOL granted, NSError *error)
            {
                if (granted)
                    [self reset];
            }];
    }

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(eventStoreChanged:)
        name:EKEventStoreChangedNotification
        object:eventStore];
}

- (void)viewDidDisappear
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self];

    _viewAppears = NO;
}

- (void)eventStoreChanged:(NSNotification *)notification
{
    [self reset];
}

- (void)reset
{
    if (!_viewAppears)
        return;

    double showsEventsInterval = self.showsEventsInterval;
    BOOL showsReminders = self.showsReminders;

    dispatch_async(dispatch_get_global_queue(0, 0), ^
    {
        if (0 >= showsEventsInterval && !showsReminders)
        {
            [self
                performSelectorOnMainThread:@selector(resetWithNil)
                withObject:nil
                waitUntilDone:NO];
            return;
        }

        if (0 < showsEventsInterval)
        {
            NSDate *now = [NSDate date];
            NSDate *end = [now dateByAddingTimeInterval:showsEventsInterval];
            NSPredicate *eventPredicate = [eventStore
                predicateForEventsWithStartDate:now endDate:end calendars:nil];
            NSArray<EKEvent *> *events = [[eventStore eventsMatchingPredicate:eventPredicate]
                sortedArrayUsingSelector:@selector(compareStartDateWithEvent:)];
            EKEvent *event = [events firstObject];
            if (nil != event)
            {
                [self
                    performSelectorOnMainThread:@selector(resetWithEvent:)
                    withObject:event
                    waitUntilDone:NO];
                return;
            }
        }

        if (showsReminders)
        {
            NSPredicate *reminderPredicate = [eventStore
                predicateForIncompleteRemindersWithDueDateStarting:nil ending:nil calendars:nil];
            [eventStore
                fetchRemindersMatchingPredicate:reminderPredicate
                completion:^(NSArray<EKReminder *> *reminders)
                {
                    reminders = [reminders
                        sortedArrayWithOptions:NSSortStable
                        usingComparator:^NSComparisonResult(id obj1, id obj2)
                        {
                            NSUInteger priority1 = [(EKReminder *)obj1 priority];
                            NSUInteger priority2 = [(EKReminder *)obj2 priority];
                            if (EKReminderPriorityNone == priority1)
                                priority1 = EKReminderPriorityLow + 1;
                            if (EKReminderPriorityNone == priority2)
                                priority2 = EKReminderPriorityLow + 1;
                            if (priority1 < priority2)
                                return NSOrderedAscending;
                            else if (priority1 > priority2)
                                return NSOrderedDescending;
                            else
                                return NSOrderedSame;
                        }];
                    EKReminder *reminder = [reminders firstObject];
                    if (nil != reminder)
                    {
                        [self
                            performSelectorOnMainThread:@selector(resetWithReminder:)
                            withObject:reminder
                            waitUntilDone:NO];
                        return;
                    }

                    [self
                        performSelectorOnMainThread:@selector(resetWithNil)
                        withObject:nil
                        waitUntilDone:NO];
                }];
        }
    });
}

- (void)resetWithEvent:(EKEvent *)event
{
    self.calendarAppIdentifier = @"com.apple.iCal";
    self.calendarIdentifier = event.calendar.calendarIdentifier;
    self.calendarItemIdentifier = event.calendarItemExternalIdentifier;

    NSString *path = [[NSWorkspace sharedWorkspace]
        absolutePathForAppBundleWithIdentifier:self.calendarAppIdentifier];
    NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:path];

    ImageTitleView *view = self.view;
    view.layoutOptions = ImageTitleViewLayoutOptionImage | ImageTitleViewLayoutOptionTitle;
    view.image = image;
    view.titleColor = [NSColor labelColor];
    view.title = event.title;
}

- (void)resetWithReminder:(EKReminder *)reminder
{
    self.calendarAppIdentifier = @"com.apple.reminders";
    self.calendarIdentifier = reminder.calendar.calendarIdentifier;
    self.calendarItemIdentifier = reminder.calendarItemIdentifier;

    NSString *path = [[NSWorkspace sharedWorkspace]
        absolutePathForAppBundleWithIdentifier:self.calendarAppIdentifier];
    NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:path];

    ImageTitleView *view = self.view;
    view.layoutOptions = ImageTitleViewLayoutOptionImage | ImageTitleViewLayoutOptionTitle;
    view.image = image;
    switch (reminder.priority)
    {
    case EKReminderPriorityHigh:
        view.titleColor = [NSColor colorWithRed:0.94 green:0.23 blue:0.13 alpha:1.0];
        break;
    case EKReminderPriorityMedium:
        view.titleColor = [NSColor colorWithRed:1.0 green:0.7 blue:0.3 alpha:1.0];
        break;
    case EKReminderPriorityLow:
        view.titleColor = [NSColor colorWithRed:1.0 green:0.93 blue:0.63 alpha:1.0];
        break;
    default:
        view.titleColor = [NSColor labelColor];
        break;
    }
    view.title = reminder.title;
}

- (void)resetWithNil
{
    self.calendarAppIdentifier = nil;
    self.calendarIdentifier = nil;
    self.calendarItemIdentifier = nil;

    ImageTitleView *view = self.view;
    view.layoutOptions = ImageTitleViewLayoutOptionTitle;
    view.image = nil;
    view.titleColor = [NSColor labelColor];
    view.title = @"--";
}

- (void)longPressAction_:(NSGestureRecognizer *)recognizer
{
    if (NSGestureRecognizerStateBegan != recognizer.state)
        return;

    [self longPressAction:self];
}

- (void)longPressAction:(id)sender
{
    NSString *source;
    if ([self.calendarAppIdentifier isEqualToString:@"com.apple.iCal"])
        source = [NSString stringWithFormat:@""
            "tell application \"Calendar\"\n"
            "    activate\n"
            "    set theCalendar to first calendar whose uid = \"%@\"\n"
            "    tell theCalendar\n"
            "        set theEvent to first event whose uid = \"%@\"\n"
            "        show theEvent\n"
            "    end tell\n"
            "end tell\n",
            self.calendarIdentifier, self.calendarItemIdentifier];
    else if ([self.calendarAppIdentifier isEqualToString:@"com.apple.reminders"])
        source = [NSString stringWithFormat:@""
            "tell application \"Reminders\"\n"
            "    activate\n"
            "    set theReminder to first reminder whose id = \"x-apple-reminder://%@\"\n"
            "    show theReminder\n"
            "end tell\n",
            self.calendarItemIdentifier];
    else
        return;

    NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:source] autorelease];
    NSDictionary *errorInfo = nil;
    [script executeAndReturnError:&errorInfo];
}
@end
