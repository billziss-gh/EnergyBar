/**
 * @file DockWidget.m
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

#import "DockWidget.h"
#import "EdgeWindowController.h"
#import "FolderController.h"
#import "NSWorkspace+Finder.h"

static NSSize dockItemSize = { 50, 30 };
static CGFloat dockDotHeight = 4;
static CGFloat dockItemBounce = 10;
static const NSUInteger maxPersistentItemCount = 8;

static NSShadow *shadowWithOffset(NSSize shadowOffset)
{
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    shadow.shadowBlurRadius = hypot(shadowOffset.width, shadowOffset.height);
    shadow.shadowOffset = shadowOffset;
    if (@available(macOS 10.14, *))
        shadow.shadowColor = [NSColor controlAccentColor];
    else
        shadow.shadowColor = [NSColor systemBlueColor];
    return shadow;
}

@interface DockWidgetApplication : NSObject <NSCopying>
@property (retain) NSString *name;
@property (retain) NSString *path;
@property (retain) NSImage *icon;
@property (assign) BOOL isDefault;
@property (assign) pid_t pid;
@property (assign) BOOL launching;
@end

@implementation DockWidgetApplication
- (void)dealloc
{
    self.name = nil;
    self.path = nil;
    self.icon = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    DockWidgetApplication *copy = [[DockWidgetApplication alloc] init];
    copy.name = self.name;
    copy.path = self.path;
    copy.icon = self.icon;
    copy.isDefault = self.isDefault;
    copy.pid = self.pid;
    copy.launching = self.launching;
    return copy;
}

- (id)key
{
    return [NSString stringWithFormat:@"%d:%@", self.pid, self.path];
}
@end

@interface DockWidgetItemView : NSScrubberItemView <NSAnimationDelegate>
@property (retain) NSView *appIconContainerView;
@property (retain) NSImageView *appIconView;
@property (retain) NSImageView *appRunningView;
@property (retain) NSString *appPath;
@property (retain, getter=getAppIcon, setter=setAppIcon:) NSImage *appIcon;
@property (assign, getter=isAppRunning, setter=setAppRunning:) BOOL appRunning;
@property (assign, getter=isAppLaunching, setter=setAppLaunching:) BOOL appLaunching;
@property (assign, getter=isProminent, setter=setProminent:) BOOL prominent;
@property (assign, getter=getDockMagnification, setter=setDockMagnification:) BOOL dockMagnification;
@end

@implementation DockWidgetItemView
{
    BOOL _appLaunching;
    BOOL _prominent;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (nil == self)
        return nil;

    self.appIconContainerView = [[[NSView alloc] initWithFrame:NSZeroRect] autorelease];
    self.appIconContainerView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

    self.appIconView = [[[NSImageView alloc] initWithFrame:NSZeroRect] autorelease];
    self.appIconView.imageScaling = NSImageScaleProportionallyDown;

    self.appRunningView = [NSImageView imageViewWithImage:[NSImage imageNamed:@"DockDot"]];
    self.appRunningView.imageScaling = NSImageScaleProportionallyDown;
    self.appRunningView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.appRunningView.hidden = YES;

    [self.appIconContainerView addSubview:self.appIconView];
    [self addSubview:self.appIconContainerView];
    [self addSubview:self.appRunningView];

    return self;
}

- (void)dealloc
{
    self.appIconContainerView = nil;
    self.appIconView = nil;
    self.appRunningView = nil;
    self.appPath = nil;

    [super dealloc];
}

- (NSImage *)getAppIcon
{
    return self.appIconView.image;
}

- (void)setAppIcon:(NSImage *)value
{
    self.appIconView.image = value;
}

- (BOOL)isAppRunning
{
    return !self.appRunningView.hidden;
}

- (void)setAppRunning:(BOOL)value
{
    self.appRunningView.hidden = !value;
}

- (BOOL)isAppLaunching
{
    return _appLaunching;
}

- (void)setAppLaunching:(BOOL)value
{
    if (_appLaunching == value)
        return;

    _appLaunching = value;
    [self bounce];
}

- (BOOL)isProminent
{
    return _prominent;
}

- (void)setProminent:(BOOL)value
{
    if (_prominent == value)
        return;

    _prominent = value;
    [self resizeAppIconView];
}

- (void)bounce
{
    if (!_appLaunching)
        return;

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
    {
        context.duration = 0.25;
        [self.appIconContainerView.animator setFrameOrigin:NSMakePoint(0, dockItemBounce)];
    }
    completionHandler:^
    {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
        {
            context.duration = 0.25;
            [self.appIconContainerView.animator setFrameOrigin:NSMakePoint(0, 0)];
        }
        completionHandler:^
        {
            [self bounce];
        }];
    }];
}

- (void)resizeAppIconView
{
    NSRect iconRect = self.bounds;
    if (iconRect.size.height >= dockDotHeight)
    {
        if (!_prominent || !self.dockMagnification)
        {
            iconRect.origin.y += dockDotHeight;
            iconRect.size.height -= dockDotHeight;
        }
        else
            iconRect.origin.y += dockDotHeight;
    }
    self.appIconView.frame = iconRect;

    if (!_prominent)
        self.appIconView.shadow = nil;
    else
        self.appIconView.shadow = shadowWithOffset(NSMakeSize(0, -dockDotHeight));
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
    [self resizeAppIconView];
    [super resizeSubviewsWithOldSize:oldSize];
}
@end

@interface DockWidgetScrubber : NSScrubber
@end

@implementation DockWidgetScrubber
- (NSInteger)tag
{
    return 'dock';
}
@end

@interface DockWidgetButton : NSButton
@property (retain) NSURL *url;
@property (retain) NSImage *regularImage;
@property (retain) NSImage *prominentImage;
@property (assign, getter=isProminent, setter=setProminent:) BOOL prominent;
- (void)resetImage;
@end

@implementation DockWidgetButton
{
    BOOL _prominent;
}

- (void)dealloc
{
    self.url = nil;
    self.regularImage = nil;
    self.prominentImage = nil;

    [super dealloc];
}

- (NSSize)intrinsicContentSize
{
    return dockItemSize;
}

- (BOOL)isProminent
{
    return _prominent;
}

- (void)setProminent:(BOOL)value
{
    if (_prominent == value)
        return;

    _prominent = value;
    [self resetImage];
}

- (void)resetImage
{
    if (!_prominent)
        self.image = self.regularImage;
    else
        self.image = self.prominentImage;

    if (!_prominent)
        self.shadow = nil;
    else
        self.shadow = shadowWithOffset(NSMakeSize(0, +dockDotHeight));
}
@end

@interface DockWidgetView : NSStackView
@property (retain) NSView *dragTargetView;
@end

@implementation DockWidgetView
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (nil == self)
        return nil;

    self.dragTargetView = [NSImageView imageViewWithImage:[NSImage imageNamed:@"DragTarget"]];
    self.dragTargetView.wantsLayer = YES;
    self.dragTargetView.layer.opacity = 0.80;
    //self.dragTargetView.layer.backgroundColor = [[NSColor colorWithWhite:1.0 alpha:0.5] CGColor];
    self.dragTargetView.layer.cornerRadius = 4;
    self.dragTargetView.translatesAutoresizingMaskIntoConstraints = NO;
    self.dragTargetView.autoresizingMask = 0;
    self.dragTargetView.hidden = YES;
    [self addSubview:self.dragTargetView];

    return self;
}

- (void)dealloc
{
    self.dragTargetView = nil;

    [super dealloc];
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(NSViewNoIntrinsicMetric, NSViewNoIntrinsicMetric);
}

- (NSView *)dragViewAtPoint:(NSPoint)point
{
    NSView *view;
    point = [self convertPoint:point fromView:nil];
    for (view = [self hitTest:point]; nil != view; view = view.superview)
        if ([view isKindOfClass:[DockWidgetItemView class]] ||
            [view isKindOfClass:[DockWidgetButton class]])
            return view;
    return nil;
}
@end

@interface DockWidget ()
<
    NSScrubberDataSource,
    NSScrubberDelegate,
    EdgeWindowControllerDelegate,
    FolderControllerDelegate
>
@property (retain) EdgeWindowController *edgeWindowController;
@property (retain) FolderController *folderController;
@property (retain) NSArray *defaultApps;
@property (retain) NSArray *runningApps;    /* running apps other than default */
@property (retain) NSView *prominentView;
@end

@implementation DockWidget
{
    NSMutableDictionary *_itemViews;
}

- (void)commonInit
{
    _itemViews = [[NSMutableDictionary alloc] init];

    self.folderController = [FolderController controller];
    self.folderController.delegate = self;

    self.customizationLabel = @"Dock";

    NSScrubberFlowLayout *layout = [[[NSScrubberFlowLayout alloc] init] autorelease];
    layout.itemSize = dockItemSize;
    NSScrubber *scrubber = [[[DockWidgetScrubber alloc]
        initWithFrame:NSMakeRect(0, 0, 200, 30)] autorelease];
    scrubber.translatesAutoresizingMaskIntoConstraints = NO;
    scrubber.dataSource = self;
    scrubber.delegate = self;
    scrubber.showsAdditionalContentIndicators = YES;
    scrubber.mode = NSScrubberModeFree;
    scrubber.continuous = NO;
    scrubber.itemAlignment = NSScrubberAlignmentNone;
    scrubber.scrubberLayout = layout;

    NSStackView *leftItemView = [NSStackView stackViewWithViews:[NSArray array]];
    leftItemView.userInterfaceLayoutDirection = NSUserInterfaceLayoutDirectionLeftToRight;
    leftItemView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    leftItemView.spacing = 0;

    NSStackView *rightItemView = [NSStackView stackViewWithViews:[NSArray array]];
    rightItemView.userInterfaceLayoutDirection = NSUserInterfaceLayoutDirectionLeftToRight;
    rightItemView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    rightItemView.spacing = 0;

    NSImageView *separator = [NSImageView imageViewWithImage:[NSImage imageNamed:@"DockSep"]];
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    separator.tag = 'sep ';

    DockWidgetButton *button = [DockWidgetButton
        buttonWithTitle:@""
        target:self
        action:@selector(trashClick:)];
    button.regularImage = [self trashImage];
    button.prominentImage = [self trashProminentImage];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.bordered = NO;
    button.tag = 'trsh';
    [button resetImage];

    DockWidgetView *view = [DockWidgetView stackViewWithViews:[NSArray arrayWithObjects:
        leftItemView,
        scrubber,
        separator,
        rightItemView,
        button,
        nil]];
    view.userInterfaceLayoutDirection = NSUserInterfaceLayoutDirectionLeftToRight;
    view.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    view.spacing = 0;
    self.view = view;
}

- (void)dealloc
{
    [[NSWorkspace sharedWorkspace]
        removeTrashObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        removeObserver:self];

    self.prominentView = nil;

    self.defaultApps = nil;
    self.runningApps = nil;

    self.folderController = nil;
    self.edgeWindowController = nil;

    [_itemViews release];

    [super dealloc];
}

- (void)viewWillAppear
{
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(resetRunningApps:)
        name:NSWorkspaceWillLaunchApplicationNotification
        object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(resetRunningApps:)
        name:NSWorkspaceDidLaunchApplicationNotification
        object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(resetRunningApps:)
        name:NSWorkspaceDidActivateApplicationNotification
        object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        addObserver:self
        selector:@selector(resetRunningApps:)
        name:NSWorkspaceDidTerminateApplicationNotification
        object:nil];
    [[NSWorkspace sharedWorkspace]
        addTrashObserver:self
        selector:@selector(trashNotify:)];

    [self reset];
}

- (void)viewDidDisappear
{
    [[NSWorkspace sharedWorkspace]
        removeTrashObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter]
        removeObserver:self];

    self.edgeWindowController = nil;
}

- (NSInteger)numberOfItemsForScrubber:(NSScrubber *)scrubber
{
    return self.apps.count;
}

- (NSScrubberItemView *)scrubber:(NSScrubber *)scrubber viewForItemAtIndex:(NSInteger)index
{
    DockWidgetApplication *app = [self.apps objectAtIndex:index];
    DockWidgetItemView *view = [_itemViews objectForKey:app.key];
    if (nil == view)
    {
        view = [[[DockWidgetItemView alloc] initWithFrame:NSZeroRect] autorelease];
        [_itemViews setObject:view forKey:app.key];
    }

    BOOL showsRunningApps = [[NSUserDefaults standardUserDefaults] boolForKey:@"showsRunningApps"];
    BOOL dockMagnification = [[NSUserDefaults standardUserDefaults] boolForKey:@"dockMagnification"];
    view.appPath = app.path;
    view.appIcon = app.icon;
    view.appRunning = showsRunningApps ? 0 != app.pid : NO;
    view.appLaunching = showsRunningApps ? app.launching : NO;
    view.prominent = NO;
    view.dockMagnification = dockMagnification;

    return view;
}

- (void)scrubber:(NSScrubber *)scrubber didSelectItemAtIndex:(NSInteger)index
{
    DockWidgetApplication *app = [self.apps objectAtIndex:index];
    if (nil != app.path)
        [[NSWorkspace sharedWorkspace] openFile:app.path withApplication:nil andDeactivate:YES];
    scrubber.selectedIndex = -1;
}

- (void)edgeWindowController:(EdgeWindowController *)controller
    mouseHoverAtPoint:(NSPoint)point
{
    [(id)self.prominentView setProminent:NO];

    if (self.folderController.presented ||
        ![[NSUserDefaults standardUserDefaults] boolForKey:@"acceptsDraggedItems"])
        return;

    if (isnan(point.x))
        return;

    DockWidgetView *view = self.view;
    NSView *dragView = [view dragViewAtPoint:point];
    if ([dragView respondsToSelector:@selector(setProminent:)])
    {
        [(id)dragView setProminent:YES];
        self.prominentView = dragView;
    }
}

- (void)edgeWindowController:(EdgeWindowController *)controller
    mouseClickAtPoint:(NSPoint)point
{
    [(id)self.prominentView setProminent:NO];

    if (self.folderController.presented ||
        ![[NSUserDefaults standardUserDefaults] boolForKey:@"acceptsDraggedItems"])
        return;

    DockWidgetView *view = self.view;
    NSView *dragView = [view dragViewAtPoint:point];
    if ([dragView isKindOfClass:[DockWidgetItemView class]])
    {
        NSString *appPath = [(DockWidgetItemView *)dragView appPath];
        if (nil != appPath)
            [[NSWorkspace sharedWorkspace] openFile:appPath withApplication:nil andDeactivate:YES];
    }
    else
    if ([dragView isKindOfClass:[DockWidgetButton class]])
    {
        NSURL *url = [(DockWidgetButton *)dragView url];
        if (nil != url)
            [[NSWorkspace sharedWorkspace] openURL:url];
        else
            [[NSWorkspace sharedWorkspace] openTrash];
    }
}

- (NSDragOperation)edgeWindowController:(EdgeWindowController *)controller
    dragURLs:(NSArray *)urls atPoint:(NSPoint)point operation:(NSDragOperation)operation
{
    DockWidgetView *view = self.view;
    NSDragOperation res = NSDragOperationNone;

    if (self.folderController.presented ||
        ![[NSUserDefaults standardUserDefaults] boolForKey:@"acceptsDraggedItems"])
    {
        view.dragTargetView.hidden = YES;
        return res;
    }

    if (nil == urls)
    {
        view.dragTargetView.hidden = YES;
        return res;
    }

    NSView *dragView = [view dragViewAtPoint:point];
    if ([dragView isKindOfClass:[DockWidgetItemView class]])
        res = 0 < urls.count ? NSDragOperationGeneric : NSDragOperationNone;
    else
    if ([dragView isKindOfClass:[DockWidgetButton class]])
    {
        NSURL *url = [(DockWidgetButton *)dragView url];
        if (nil != url)
        {
            NSNumber *value;
            BOOL isDir = [url getResourceValue:&value forKey:NSURLIsDirectoryKey error:0] &&
                [value boolValue];
            BOOL isApp = [url getResourceValue:&value forKey:NSURLIsApplicationKey error:0] &&
                [value boolValue];
            if (isApp)
                res = 0 < urls.count ? NSDragOperationGeneric : NSDragOperationNone;
            else if (isDir)
            {
                res = NSDragOperationCopy;
                if (0 < urls.count)
                    switch (operation)
                    {
                    case NSDragOperationCopy:
                        res = NSDragOperationCopy;
                        break;
                    case NSDragOperationCopy | NSDragOperationGeneric:
                    case NSDragOperationLink:
                        res = NSDragOperationLink;
                        break;
                    default:
                        res = NSDragOperationGeneric;
                        break;
                    }
            }
        }
        else
            /* trash */
            res = 0 < urls.count ? NSDragOperationGeneric : NSDragOperationNone;
    }

    view.dragTargetView.frame = [view convertRect:dragView.visibleRect fromView:dragView];
    view.dragTargetView.hidden = NSDragOperationNone == res;

    return res;
}

- (BOOL)edgeWindowController:(EdgeWindowController *)controller
    dropURLs:(NSArray *)urls atPoint:(NSPoint)point operation:(NSDragOperation)operation
    destination:(NSURL **)destination
{
    DockWidgetView *view = self.view;
    BOOL res = NO;

    if (self.folderController.presented ||
        ![[NSUserDefaults standardUserDefaults] boolForKey:@"acceptsDraggedItems"])
    {
        view.dragTargetView.hidden = YES;
        return res;
    }

    NSView *dragView = [view dragViewAtPoint:point];
    if ([dragView isKindOfClass:[DockWidgetItemView class]])
    {
        NSString *appPath = [(DockWidgetItemView *)dragView appPath];
        if (nil != appPath)
            res = 0 < urls.count &&
                nil != [[NSWorkspace sharedWorkspace]
                    openURLs:urls
                    withApplicationAtURL:[NSURL fileURLWithPath:appPath]
                    options:NSWorkspaceLaunchAsync
                    configuration:[NSDictionary dictionary]
                    error:0];
    }
    else
    if ([dragView isKindOfClass:[DockWidgetButton class]])
    {
        NSURL *url = [(DockWidgetButton *)dragView url];
        if (nil != url)
        {
            NSNumber *value;
            BOOL isDir = [url getResourceValue:&value forKey:NSURLIsDirectoryKey error:0] &&
                [value boolValue];
            BOOL isApp = [url getResourceValue:&value forKey:NSURLIsApplicationKey error:0] &&
                [value boolValue];
            if (isApp)
                res = 0 < urls.count &&
                    nil != [[NSWorkspace sharedWorkspace]
                        openURLs:urls
                        withApplicationAtURL:url
                        options:NSWorkspaceLaunchAsync
                        configuration:[NSDictionary dictionary]
                        error:0];
            else if (isDir)
            {
                if (0 < urls.count)
                    switch (operation)
                    {
                    case NSDragOperationCopy:
                        res = [[NSWorkspace sharedWorkspace] copyItemsAtURLs:urls toURL:url];
                        break;
                    case NSDragOperationCopy | NSDragOperationGeneric:
                    case NSDragOperationLink:
                        res = [[NSWorkspace sharedWorkspace] aliasItemsAtURLs:urls toURL:url];
                        break;
                    default:
                        res = [[NSWorkspace sharedWorkspace] moveItemsAtURLs:urls toURL:url];
                        break;
                    }
                else if (0 != destination)
                {
                    *destination = url;
                    res = YES;
                }
            }
        }
        else
            /* trash */
            res = 0 < urls.count && [[NSWorkspace sharedWorkspace] moveItemsToTrash:urls];
    }

    view.dragTargetView.hidden = YES;

    return res;
}

- (void)folderController:(FolderController *)controller didSelectURL:(NSURL *)url
{
    if (![url.path hasPrefix:[[NSWorkspace sharedWorkspace] trashPath]])
    {
        [[NSWorkspace sharedWorkspace] openURL:url];
        [controller dismiss];
    }
}

- (void)folderController:(FolderController *)controller didClick:(NSString *)identifier
{
    if ([identifier isEqualToString:@"openButton"])
    {
        if (![controller.url.path hasPrefix:[[NSWorkspace sharedWorkspace] trashPath]])
            [[NSWorkspace sharedWorkspace] openURL:controller.url];
        else
            [[NSWorkspace sharedWorkspace] openTrash];
    }
    else
    if ([identifier isEqualToString:@"emptyButton"])
        [[NSWorkspace sharedWorkspace] emptyTrash];
    [controller dismiss];
}

- (NSArray *)apps
{
    BOOL updateItemViews = NO;

    if (nil == self.defaultApps)
    {
        self.runningApps = nil;

        NSMutableArray *newDefaultApps = [NSMutableArray array];
        [self enumerateDefaultAppsFolder:^(NSURL *url, NSStackViewGravity gravity)
        {
            if (NSStackViewGravityCenter != gravity)
                return;

            DockWidgetApplication *app = [[[DockWidgetApplication alloc] init] autorelease];
            app.name = [url.path lastPathComponent];
            app.path = url.path;
            app.icon = [[NSWorkspace sharedWorkspace] iconForFile:app.path];
            app.isDefault = YES;
            [newDefaultApps addObject:app];
        }];

        if (0 == newDefaultApps.count)
        {
            NSArray *defaultApps = [[NSUserDefaults standardUserDefaults] arrayForKey:@"defaultApps"];
            for (NSDictionary *a in defaultApps)
            {
                DockWidgetApplication *app = [[[DockWidgetApplication alloc] init] autorelease];
                app.name = [a objectForKey:@"NSApplicationName"];
                app.path = [a objectForKey:@"NSApplicationPath"];
                app.icon = [[NSWorkspace sharedWorkspace] iconForFile:app.path];
                app.isDefault = YES;
                [newDefaultApps addObject:app];
            }
        }

        self.defaultApps = [[newDefaultApps copy] autorelease];

        updateItemViews = YES;
    }

    if (nil == self.runningApps)
    {
        NSMutableDictionary *defaultAppsDict = [NSMutableDictionary dictionary];
        for (DockWidgetApplication *app in self.defaultApps)
        {
            app.pid = 0;
            app.launching = NO;
            [defaultAppsDict setObject:app forKey:app.path];
        }

        NSMutableArray *newRunningApps = [NSMutableArray array];

        NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
        for (NSRunningApplication *a in runningApps)
        {
            if (NSApplicationActivationPolicyRegular != a.activationPolicy)
                continue;

            DockWidgetApplication *app;
            NSString *path = a.bundleURL.path;
            if (nil != (app = [defaultAppsDict objectForKey:path]) && 0 == app.pid)
            {
                app.icon = a.icon;
                app.pid = a.processIdentifier;
                app.launching = !a.finishedLaunching;
                continue;
            }

            app = [[[DockWidgetApplication alloc] init] autorelease];
            app.name = a.localizedName;
            app.path = a.bundleURL.path;
            app.icon = a.icon;
            app.pid = a.processIdentifier;
            app.launching = !a.finishedLaunching;
            [newRunningApps addObject:app];
        }

        self.runningApps = [[newRunningApps copy] autorelease];

        updateItemViews = YES;
    }

    BOOL showsRunningApps = [[NSUserDefaults standardUserDefaults] boolForKey:@"showsRunningApps"];
    NSArray *apps = showsRunningApps ?
        [self.defaultApps arrayByAddingObjectsFromArray:self.runningApps] :
        self.defaultApps;

    if (updateItemViews)
    {
        NSMutableDictionary *itemViews = _itemViews;

        _itemViews = [[NSMutableDictionary alloc] init];
        for (DockWidgetApplication *app in apps)
        {
            id key = app.key;
            id obj = [itemViews objectForKey:key];
            if (nil != obj)
                [_itemViews setObject:obj forKey:key];
        }

        /* work around a problem in NSScrubber(?) */
        for (id key in itemViews)
            if (nil == [_itemViews objectForKey:key])
            {
                DockWidgetItemView *view = [itemViews objectForKey:key];
                view.appPath = nil;
                view.appIcon = nil;
                view.appRunning = NO;
                view.appLaunching = NO;
                view.prominent = NO;
                view.dockMagnification = NO;
            }

        [itemViews release];
    }

    return apps;
}

- (void)enumerateDefaultAppsFolder:(void (^)(NSURL *url, NSStackViewGravity gravity))block
{
    NSString *defaultAppsFolder = [[NSUserDefaults standardUserDefaults]
        stringForKey:@"defaultAppsFolder"];
    if (nil != defaultAppsFolder)
    {
        NSArray *contents = [[NSFileManager defaultManager]
            contentsOfDirectoryAtPath:defaultAppsFolder error:0];
        contents = [contents sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
        for (NSString *c in contents)
        {
            if ([c hasPrefix:@"."])
                continue;

            NSURL *url = [NSURL
                URLByResolvingAliasFileAtURL:[NSURL
                    fileURLWithPath:[defaultAppsFolder stringByAppendingPathComponent:c]]
                options:NSURLBookmarkResolutionWithoutUI|NSURLBookmarkResolutionWithoutMounting
                error:0];
            if (nil == url)
                continue;

            NSStackViewGravity gravity;
            NSNumber *value;
            if ([c hasSuffix:@".lpinned"])
                gravity = NSStackViewGravityLeading;
            else if ([c hasSuffix:@".pinned"])
                gravity = NSStackViewGravityTrailing;
            else if ([url getResourceValue:&value forKey:NSURLIsApplicationKey error:0] &&
                [value boolValue])
                gravity = NSStackViewGravityCenter;
            else
                gravity = NSStackViewGravityTrailing;
            block(url, gravity);
        }
    }
}

- (void)reset
{
    [self resetDrag];
    [self resetPersistentItems];
    [self resetDefaultApps];
}

- (void)resetDrag
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"acceptsDraggedItems"])
    {
        self.edgeWindowController = [EdgeWindowController controller];
        self.edgeWindowController.delegate = self;
    }
    else
        self.edgeWindowController = nil;
}

- (void)resetDefaultApps
{
    NSScrubber *scrubber = [self.view viewWithTag:'dock'];
    self.defaultApps = nil;
    [scrubber reloadData];
}

- (void)resetPersistentItems
{
    NSMutableArray *leftViews = [NSMutableArray array];
    NSMutableArray *rightViews = [NSMutableArray array];
    [self enumerateDefaultAppsFolder:^(NSURL *url, NSStackViewGravity gravity)
    {
        switch (gravity)
        {
        case NSStackViewGravityLeading:
            if (maxPersistentItemCount < leftViews.count)
                return;
            break;
        case NSStackViewGravityTrailing:
            if (maxPersistentItemCount < rightViews.count)
                return;
            break;
        default:
            return;
        }

        NSSize iconSize = NSMakeSize(dockItemSize.height, dockItemSize.height); // square!
        NSRect iconRect = NSMakeRect(dockDotHeight / 2, dockDotHeight,
            iconSize.height - dockDotHeight, iconSize.height - dockDotHeight);  // square!
        NSRect prominentIconRect = NSMakeRect(0, dockDotHeight,
            iconSize.height, iconSize.height);  // square!
        NSImage *image = [self
            makeImageWithSize:iconSize
            drawImage:[[NSWorkspace sharedWorkspace] iconForFile:url.path]
            inRect:iconRect];
        NSImage *prominentImage = [self
            makeImageWithSize:iconSize
            drawImage:[[NSWorkspace sharedWorkspace] iconForFile:url.path]
            inRect:prominentIconRect];
        DockWidgetButton *button = [DockWidgetButton
            buttonWithTitle:@""
            target:self
            action:@selector(persistentItemClick:)];
        button.regularImage = image;
        button.prominentImage = prominentImage;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.bordered = NO;
        button.url = url;
        [button resetImage];

        switch (gravity)
        {
        case NSStackViewGravityLeading:
            [leftViews addObject:button];
            break;
        case NSStackViewGravityTrailing:
            [rightViews addObject:button];
            break;
        default:
            break;
        }
    }];

    BOOL showsTrash = [[NSUserDefaults standardUserDefaults] boolForKey:@"showsTrash"];
    [self.view viewWithTag:'sep '].hidden = !(showsTrash || 0 < rightViews.count);
    [self.view viewWithTag:'trsh'].hidden = !showsTrash;

    DockWidgetView *view = self.view;
    NSStackView *leftItemView = [view.views objectAtIndex:0];
    NSStackView *rightItemView = [view.views objectAtIndex:3];

    [leftItemView setViews:leftViews inGravity:NSStackViewGravityTrailing];
    [rightItemView setViews:rightViews inGravity:NSStackViewGravityTrailing];
}

- (void)resetRunningApps:(NSNotification *)notification
{
    //NSLog(@"%s %@", __func__, notification);
    @try
    {
        NSScrubber *scrubber = [self.view viewWithTag:'dock'];
        [scrubber performSequentialBatchUpdates:^(void)
        {
            NSUInteger count = scrubber.numberOfItems;
            NSArray *oldApps = [[[NSArray alloc] initWithArray:self.apps copyItems:YES] autorelease];
            self.runningApps = nil;
            NSArray *newApps = self.apps;

            NSMutableDictionary *oldAppsDict = [NSMutableDictionary dictionary];
            for (DockWidgetApplication *oldApp in oldApps)
            {
                NSArray *oldAppsArray = [oldAppsDict objectForKey:oldApp.path];
                if (nil == oldAppsArray)
                    oldAppsArray = [NSArray arrayWithObject:oldApp];
                else
                    oldAppsArray = [oldAppsArray arrayByAddingObject:oldApp];
                [oldAppsDict setObject:oldAppsArray forKey:oldApp.path];
            }

            NSMutableDictionary *newAppsDict = [NSMutableDictionary dictionary];
            for (DockWidgetApplication *newApp in newApps)
            {
                NSArray *newAppsArray = [newAppsDict objectForKey:newApp.path];
                if (nil == newAppsArray)
                    newAppsArray = [NSArray arrayWithObject:newApp];
                else
                    newAppsArray = [newAppsArray arrayByAddingObject:newApp];
                [newAppsDict setObject:newAppsArray forKey:newApp.path];
            }

            /* handle multiple instances for a default app that is terminating */
            for (NSUInteger i = 0; oldApps.count > i; i++)
            {
                DockWidgetApplication *oldApp = [oldApps objectAtIndex:i];
                if (!oldApp.isDefault)
                    break; /* default apps are always first */

                NSArray *newAppsArray = [newAppsDict objectForKey:oldApp.path];
                if (1 <= newAppsArray.count)
                {
                    DockWidgetApplication *newApp = [newAppsArray objectAtIndex:0];
                    NSArray *oldAppsArray = [oldAppsDict objectForKey:oldApp.path];
                    for (NSUInteger j = 1; oldAppsArray.count > j; j++)
                    {
                        DockWidgetApplication *a = [oldAppsArray objectAtIndex:j];
                        if (newApp.pid == a.pid)
                        {
                            pid_t pid = oldApp.pid;
                            oldApp.pid = a.pid;
                            a.pid = pid;

                            BOOL launching = oldApp.launching;
                            oldApp.launching = a.launching;
                            a.launching = launching;

                            break;
                        }
                    }
                }
            }

            /* remove items for old apps that are not in the new apps */
            for (NSUInteger i = oldApps.count - 1; oldApps.count > i; i--)
            {
                DockWidgetApplication *oldApp = [oldApps objectAtIndex:i];
                NSArray *newAppsArray = [newAppsDict objectForKey:oldApp.path];

                BOOL update = YES;
                for (DockWidgetApplication *newApp in newAppsArray)
                    if (0 == oldApp.pid || 0 == newApp.pid || oldApp.pid == newApp.pid)
                    {
                        update = NO;
                        break;
                    }

                if (update)
                {
                    [scrubber removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:i]];
                    count--;
                }
            }

            /* insert items for new apps that are not in the old apps */
            for (NSUInteger i = 0; newApps.count > i; i++)
            {
                DockWidgetApplication *newApp = [newApps objectAtIndex:i];
                NSArray *oldAppsArray = [oldAppsDict objectForKey:newApp.path];

                BOOL update = YES;
                for (DockWidgetApplication *oldApp in oldAppsArray)
                    if (0 == oldApp.pid || 0 == newApp.pid || oldApp.pid == newApp.pid)
                    {
                        update = NO;
                        break;
                    }

                if (update)
                {
                    [scrubber insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:count]];
                    count++;
                }
            }

            for (NSUInteger i = 0; oldApps.count > i; i++)
            {
                DockWidgetApplication *oldApp = [oldApps objectAtIndex:i];
                NSArray *newAppsArray = [newAppsDict objectForKey:oldApp.path];

                BOOL update = YES;
                for (DockWidgetApplication *newApp in newAppsArray)
                    if (oldApp.pid == newApp.pid && oldApp.launching == newApp.launching)
                    {
                        update = NO;
                        break;
                    }

                if (update)
                    [scrubber reloadItemsAtIndexes:[NSIndexSet indexSetWithIndex:i]];
            }
        }];
    }
    @catch (NSException *ex)
    {
        NSLog(@"%@", ex);

        NSScrubber *scrubber = [self.view viewWithTag:'dock'];
        self.runningApps = nil;
        [scrubber reloadData];
    }
}

- (void)persistentItemClick:(id)sender
{
    NSURL *url = [sender url];
    if (nil != url)
    {
        NSNumber *value;
        BOOL isDir = [url getResourceValue:&value forKey:NSURLIsDirectoryKey error:0] &&
            [value boolValue];
        BOOL isPkg = [url getResourceValue:&value forKey:NSURLIsPackageKey error:0] &&
            [value boolValue];
        BOOL isApp = [url getResourceValue:&value forKey:NSURLIsApplicationKey error:0] &&
            [value boolValue];
        BOOL open = ![[NSUserDefaults standardUserDefaults] boolForKey:@"showsFoldersInTouchBar"];
        if (!isDir || isPkg || isApp)
            [[NSWorkspace sharedWorkspace] openURL:url];
        else if (open)
            [[NSWorkspace sharedWorkspace] openURL:url];
        else
        {
            BOOL isApplications = [url.path isEqualToString:@"/Applications"];
            BOOL isDownloads = [url.path
                isEqualToString:[NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"]];
            self.folderController.url = url;
            self.folderController.includeDescendants = NO; //isApplications;
            self.folderController.sortKey = isDownloads ? NSURLAddedToDirectoryDateKey : nil;
            self.folderController.imagePosition = isApplications ? NSImageOnly : NSImageLeft;
            self.folderController.showsEmptyButton = NO;
            [self.folderController present];
        }
    }
}

- (NSImage *)trashImage
{
    BOOL full = [[NSWorkspace sharedWorkspace] isTrashFull];
    return [NSImage imageNamed:full ? @"TrashFull" : @"TrashEmpty"];
}

- (NSImage *)trashProminentImage
{
    BOOL full = [[NSWorkspace sharedWorkspace] isTrashFull];
    return [NSImage imageNamed:full ? @"TrashProminentFull" : @"TrashProminentEmpty"];
}

- (void)trashNotify:(NSNotification *)notification
{
    DockWidgetButton *button = [self.view viewWithTag:'trsh'];
    button.regularImage = [self trashImage];
    button.prominentImage = [self trashProminentImage];
    [button resetImage];
}

- (void)trashClick:(id)sender
{
    BOOL open = ![[NSUserDefaults standardUserDefaults] boolForKey:@"showsFoldersInTouchBar"];
    if (open)
        [[NSWorkspace sharedWorkspace] openTrash];
    else
    {
        self.folderController.url = [NSURL
            fileURLWithPath:[[NSWorkspace sharedWorkspace] trashPath]];
        self.folderController.includeDescendants = NO;
        self.folderController.sortKey = nil;
        self.folderController.imagePosition = NSImageLeft;
        self.folderController.showsEmptyButton = YES;
        self.folderController.emptyButtonEnabled = [[NSWorkspace sharedWorkspace] isTrashFull];
        [self.folderController present];
    }
}

- (NSImage *)makeImageWithSize:(NSSize)newSize
    drawImage:(NSImage *)oldImage inRect:(NSRect)newRect
{
    NSSize oldSize = oldImage.size;
    NSImage *newImage = [[[NSImage alloc] initWithSize:newSize] autorelease];
    [newImage lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [oldImage
        drawInRect:newRect
        fromRect:NSMakeRect(0, 0, oldSize.width, oldSize.height)
        operation:NSCompositingOperationSourceOver
        fraction:1.0];
    [newImage unlockFocus];
    return newImage;
}
@end
