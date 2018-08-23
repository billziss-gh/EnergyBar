/**
 * @file ControlWidget.m
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

#import "ControlWidget.h"
#import "AudioVolume.h"
#import "Brightness.h"
#import "CBBlueLightClient.h"
#import "KeyEvent.h"
#import "NSTouchBar+SystemModal.h"
#import "NowPlaying.h"
#import "TouchBarController.h"

@interface ControlWidgetPopoverBarSlider : NSSlider
@end

@implementation ControlWidgetPopoverBarSlider
- (NSSize)intrinsicContentSize
{
    NSSize size = [super intrinsicContentSize];
    size.width = 250;
    return size;
}
@end

@interface ControlWidgetPopoverBarController : TouchBarController
@end

@implementation ControlWidgetPopoverBarController
+ (id)controllerWithNibNamed:(NSString *)name
{
    id controller = [[[[self class] alloc] init] autorelease];
    NSArray *objects = nil;

    if (![[NSBundle mainBundle]
        loadNibNamed:name owner:controller topLevelObjects:&objects])
        return nil;

    return controller;
}

- (IBAction)close:(id)sender
{
    [self dismiss];
}
@end

@interface ControlWidgetBrightnessBarController : ControlWidgetPopoverBarController
@property (retain) CBBlueLightClient *blueLightClient;
@property (retain) IBOutlet NSButton *nightShiftButton;
@end

@implementation ControlWidgetBrightnessBarController
+ (id)controller
{
    return [self controllerWithNibNamed:@"BrightnessBar"];
}

- (id)init
{
    self = [super init];
    if (nil == self)
        return nil;

    self.blueLightClient = [[[CBBlueLightClient alloc] init] autorelease];
    [self.blueLightClient setStatusNotificationBlock:^{
        [self performSelectorOnMainThread:@selector(resetNightShift) withObject:nil waitUntilDone:NO];
    }];

    return self;
}

- (void)dealloc
{
    self.blueLightClient = nil;
    self.nightShiftButton = nil;

    [super dealloc];
}

- (void)awakeFromNib
{
    NSSliderTouchBarItem *item;

    item = [self.touchBar itemForIdentifier:@"BrightnessSlider"];
    item.slider.minValue = 0;
    item.slider.maxValue = 1;
    item.slider.altIncrementValue = 1.0 / 16;
    item.minimumValueAccessory.behavior = NSSliderAccessoryBehavior.valueStepBehavior;
    item.maximumValueAccessory.behavior = NSSliderAccessoryBehavior.valueStepBehavior;

#if 0
    item = [self.touchBar itemForIdentifier:@"KeyboardBrightnessSlider"];
    item.slider.minValue = 0;
    item.slider.maxValue = 1;
    item.slider.altIncrementValue = 1.0 / 16;
    item.minimumValueAccessory.behavior = NSSliderAccessoryBehavior.valueStepBehavior;
    item.maximumValueAccessory.behavior = NSSliderAccessoryBehavior.valueStepBehavior;
#endif

    [super awakeFromNib];
}

- (BOOL)presentWithPlacement:(NSInteger)placement
{
    NSSliderTouchBarItem *item;
    double value;

    value = GetDisplayBrightness();
    if (isnan(value))
        value = 0.5;

    item = [self.touchBar itemForIdentifier:@"BrightnessSlider"];
    item.slider.doubleValue = value;

    [self resetNightShift];

#if 0
    value = GetKeyboardBrightness();
    if (isnan(value))
        value = 0.5;

    item = [self.touchBar itemForIdentifier:@"KeyboardBrightnessSlider"];
    item.slider.doubleValue = value;
#endif

    return [super presentWithPlacement:placement];
}

- (IBAction)nightShiftButtonClick:(id)sender
{
    switch ([sender state])
    {
    case NSControlStateValueOn:
        [self.blueLightClient setEnabled:YES];
        break;
    case NSControlStateValueOff:
        [self.blueLightClient setEnabled:NO];
        break;
    default:
        NSLog(@"nightShiftButtonClick: %d", (int)[sender state]);
        break;
    }
}

- (IBAction)brightnessSliderAction:(id)sender
{
    NSSliderTouchBarItem *item = [self.touchBar itemForIdentifier:@"BrightnessSlider"];
    SetDisplayBrightness(item.slider.doubleValue);
}

- (void)resetNightShift
{
    CBBlueLightStatus status;
    if ([self.blueLightClient getBlueLightStatus:&status])
        self.nightShiftButton.state = status.enabled ? NSControlStateValueOn : NSControlStateValueOff;
}

#if 0
- (IBAction)keyboardBrightnessSliderAction:(id)sender
{
    NSSliderTouchBarItem *item = [self.touchBar itemForIdentifier:@"KeyboardBrightnessSlider"];
    SetKeyboardBrightness(item.slider.doubleValue);
}
#endif
@end

@interface ControlWidgetVolumeBarController : ControlWidgetPopoverBarController
@end

@implementation ControlWidgetVolumeBarController
+ (id)controller
{
    return [self controllerWithNibNamed:@"VolumeBar"];
}

- (void)awakeFromNib
{
    NSSliderTouchBarItem *item = [self.touchBar itemForIdentifier:@"VolumeSlider"];
    item.slider.minValue = 0;
    item.slider.maxValue = 1;
    item.slider.altIncrementValue = 1.0 / 16;
    item.minimumValueAccessory.behavior = NSSliderAccessoryBehavior.valueStepBehavior;
    item.maximumValueAccessory.behavior = NSSliderAccessoryBehavior.valueStepBehavior;

    [super awakeFromNib];
}

- (BOOL)presentWithPlacement:(NSInteger)placement
{
    double value = GetAudioVolume();
    if (isnan(value))
        value = 0.5;

    NSSliderTouchBarItem *item = [self.touchBar itemForIdentifier:@"VolumeSlider"];
    item.slider.doubleValue = value;

    return [super presentWithPlacement:placement];
}

- (IBAction)volumeSliderAction:(id)sender
{
    NSSliderTouchBarItem *item = [self.touchBar itemForIdentifier:@"VolumeSlider"];
    SetAudioVolume(item.slider.doubleValue);
    SetAudioMuted(item.slider.doubleValue < 1.0 / (16 * 4));
}
@end

@interface ControlWidget ()
@property (retain) ControlWidgetBrightnessBarController *brightnessBarController;
@property (retain) ControlWidgetVolumeBarController *volumeBarController;
- (void)resetMute;
@end

void ControlWidgetMuteListener(void *data)
{
    [(id)data performSelectorOnMainThread:@selector(resetMute) withObject:nil waitUntilDone:NO];
}

@implementation ControlWidget
{
    struct AudioPropertyListener _muteListener;
}

- (void)commonInit
{
    self.brightnessBarController = [ControlWidgetBrightnessBarController controller];
    self.volumeBarController = [ControlWidgetVolumeBarController controller];

    NSPressGestureRecognizer *recognizer = [[[NSPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(pressAction:)] autorelease];
    recognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    recognizer.minimumPressDuration = 1.0;
    NSSegmentedControl *control = [NSSegmentedControl
        segmentedControlWithImages:[NSArray arrayWithObjects:
            [self playPauseImage],
            [NSImage imageNamed:@"BrightnessUp"],
            [NSImage imageNamed:NSImageNameTouchBarAudioOutputVolumeHighTemplate],
            [self volumeMuteImage],
            nil]
        trackingMode:NSSegmentSwitchTrackingMomentary
        target:self
        action:@selector(click:)];
    [control addGestureRecognizer:recognizer];

    self.customizationLabel = @"Control";
    self.view = control;

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(nowPlayingNotification:)
        name:@"NowPlayingState"
        object:nil];
    [NowPlaying sharedInstance];

    _muteListener.code = ControlWidgetMuteListener;
    _muteListener.data = self;
    AddAudioMutedListener(&_muteListener);
}

- (void)dealloc
{
    RemoveAudioMutedListener(&_muteListener);

    [[NSNotificationCenter defaultCenter]
        removeObserver:self];

    self.brightnessBarController = nil;
    self.volumeBarController = nil;

    [super dealloc];
}

- (NSImage *)playPauseImage
{
    BOOL playing = [NowPlaying sharedInstance].playing;
    return [NSImage imageNamed:playing ?
        NSImageNameTouchBarPauseTemplate : NSImageNameTouchBarPlayTemplate];
}

- (void)resetPlayPause
{
    NSSegmentedControl *control = self.view;
    [control setImage:[self playPauseImage] forSegment:0];
}

- (NSImage *)volumeMuteImage
{
    bool mute = IsAudioMuted();
    return [NSImage imageNamed:mute ? @"VolumeMuteOn" : @"VolumeMuteOff"];
}

- (void)resetMute
{
    NSSegmentedControl *control = self.view;
    [control setImage:[self volumeMuteImage] forSegment:3];
}

- (void)nowPlayingNotification:(NSNotification *)notification
{
    [self resetPlayPause];
}

- (void)click:(id)sender
{
    NSSegmentedControl *control = sender;
    switch (control.selectedSegment)
    {
    case 0:
        PostAuxKeyPress(NX_KEYTYPE_PLAY);
        break;
    case 1:
        [self.brightnessBarController present];
        break;
    case 2:
        [self.volumeBarController present];
        break;
    case 3:
        SetAudioMuted(!IsAudioMuted());
        break;
    }
}

- (void)pressAction:(NSGestureRecognizer *)recognizer
{
    if (NSGestureRecognizerStateBegan != recognizer.state)
        return;

    /* HACK:
     * There does not appear to be a direct way to determine the segment from a point.
     *
     * One would think that the -[NSSegmentedControl widthForSegment:] method on the
     * first segment (which happens to be the Play/Pause button) would do the trick.
     * Unfortunately this method returns 0 for automatically sized segments. Arrrrr!
     *
     * So I am adapting here some code that I wrote a long time for "DarwinKit"...
     */
    NSSegmentedControl *control = self.view;
    NSRect rect = control.bounds;
    CGFloat widths[16] = { 0 }, totalWidth = 0;
    NSInteger count = control.segmentCount, zeroWidthCells = 0;
    for (NSInteger i = 0; count > i; i++)
    {
        widths[i] = [control widthForSegment:i];
        if (0 == widths[i])
            zeroWidthCells++;
        else
            totalWidth += widths[i];
    }

    if (0 < zeroWidthCells)
    {
        totalWidth = rect.size.width - totalWidth;
        for (NSInteger i = 0; count > i; i++)
            if (0 == widths[i])
                widths[i] = totalWidth / zeroWidthCells;
    }
    else
    {
        if (2 <= count)
        {
            CGFloat remWidth = rect.size.width - totalWidth;
            widths[0] += remWidth / 2;
            widths[count - 1] += remWidth / 2;
        }
        else if (1 <= count)
        {
            CGFloat remWidth = rect.size.width - totalWidth;
            widths[0] += remWidth;
        }
    }

    NSPoint point = [recognizer locationInView:control];

    if (0 < point.x && point.x < widths[0])
        PostAuxKeyPress(NX_KEYTYPE_NEXT);
}
@end
