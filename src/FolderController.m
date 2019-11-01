/**
 * @file FolderController.m
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

#import "FolderController.h"
#import <QuickLook/QuickLook.h>
#import "ImageTitleView.h"

static const NSSize smallItemSize = { 50, 30 };
static const NSSize largeItemSize = { 150, 30 };
static const NSUInteger maxFileCount = 100;

@interface FolderItem : NSObject
@property (retain) NSURL *url;
@property (retain) NSImage *icon;
@end

@implementation FolderItem
- (void)dealloc
{
    self.url = nil;
    self.icon = nil;
    [super dealloc];
}
@end

@interface FolderItemView : NSScrubberItemView
@property (retain) ImageTitleView *imageTitleView;
@end

@implementation FolderItemView
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (nil == self)
        return nil;

    self.imageTitleView = [[[ImageTitleView alloc] initWithFrame:NSZeroRect] autorelease];
    self.imageTitleView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageTitleView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.imageTitleView.titleFont = [NSFont systemFontOfSize:[NSFont
        systemFontSizeForControlSize:NSControlSizeSmall]];
    self.imageTitleView.titleLineBreakMode = NSLineBreakByTruncatingTail;
    self.imageTitleView.layoutOptions =
        ImageTitleViewLayoutOptionImage |
        ImageTitleViewLayoutOptionTitle;
    [self addSubview:self.imageTitleView];

    return self;
}

- (void)dealloc
{
    self.imageTitleView = nil;

    [super dealloc];
}

- (void)removeFromSuperview
{
    /* work around a problem in NSScrubber(?) */
    self.hidden = YES;
    [super removeFromSuperview];
}
@end

@interface FolderController ()
@property (retain) IBOutlet NSScrubber *scrubber;
@property (retain) IBOutlet NSTextField *label;
@property (retain) IBOutlet NSButton *emptyButton;
@property (retain) IBOutlet NSButton *openButton;
@property (retain) NSArray<FolderItem *> *contents;
@property (assign) BOOL tooManyItems;
@end

@implementation FolderController
+ (id)controller
{
    return [self controllerWithNibNamed:@"FolderBar"];
}

- (void)dealloc
{
    self.scrubber = nil;
    self.label = nil;
    self.emptyButton = nil;
    self.openButton = nil;
    self.contents = nil;
    self.url = nil;

    [super dealloc];
}

- (void)awakeFromNib
{
    [self.scrubber registerClass:[FolderItemView class] forItemIdentifier:@"item"];
}

- (BOOL)presentWithPlacement:(NSInteger)placement
{
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
        enumeratorAtURL:self.url
        includingPropertiesForKeys: nil != self.sortKey ?
            [NSArray arrayWithObjects:NSURLIsDirectoryKey, NSURLIsApplicationKey, self.sortKey, nil] :
            nil
        options:
            (self.includeDescendants ? 0 : NSDirectoryEnumerationSkipsSubdirectoryDescendants) |
            NSDirectoryEnumerationSkipsPackageDescendants |
            NSDirectoryEnumerationSkipsHiddenFiles
        errorHandler:nil];
    NSMutableArray<NSURL *> *urls = [NSMutableArray array];
    BOOL tooManyItems = NO;
    NSURL *url;
    while (0 != (url = [enumerator nextObject]))
    {
        if (maxFileCount <= urls.count)
        {
            tooManyItems = YES;
            break;
        }
        [urls addObject:url];
    }
    [urls sortUsingComparator:^NSComparisonResult(id obj1, id obj2)
    {
        NSURL *url1 = obj1;
        NSURL *url2 = obj2;
        NSURLResourceKey sortKey = self.sortKey;
        if (nil != sortKey)
        {
            NSDate *val1, *val2;
            if ([url1 getResourceValue:&val1 forKey:sortKey error:0] &&
                [url2 getResourceValue:&val2 forKey:sortKey error:0])
            {
                return [val2 compare:val1];
            }
        }
        return [url1.path localizedStandardCompare:url2.path];
    }];

    NSMutableArray<FolderItem *> *contents = [NSMutableArray array];
    NSImage *appIcon = [[NSWorkspace sharedWorkspace] iconForFileType:@".app"];
    NSImage *dirIcon = [[NSWorkspace sharedWorkspace] iconForFileType:@"public.folder"];
    NSImage *docIcon = [[NSWorkspace sharedWorkspace] iconForFileType:@"public.content"];
    for (NSURL *url in urls)
    {
        NSNumber *value;
        BOOL isDir = [url getResourceValue:&value forKey:NSURLIsDirectoryKey error:0] && [value boolValue];
        BOOL isApp = [url getResourceValue:&value forKey:NSURLIsApplicationKey error:0] && [value boolValue];

        FolderItem *item = [[FolderItem alloc] init];
        item.url = url;
        item.icon = isApp ? appIcon : (isDir ? dirIcon : docIcon);
        [contents addObject:item];
        [item release];
    }
    self.contents = contents;
    self.tooManyItems = tooManyItems;

    [self.scrubber.scrubberLayout
        setItemSize:NSImageOnly != self.imagePosition ? largeItemSize : smallItemSize];
    [self.scrubber reloadData];

    self.label.stringValue = [NSString stringWithFormat:@"%u%@ file%@",
        (unsigned)self.contents.count,
        self.tooManyItems ? @"+" : @"",
        1 != self.contents.count ? @"s" : @""];

    NSMutableArray *itemIdentifiers = [[self.touchBar.defaultItemIdentifiers mutableCopy]
        autorelease];
    [itemIdentifiers removeObject:@"emptyButton"];
    if (self.showsEmptyButton)
    {
        NSUInteger index = [itemIdentifiers indexOfObject:@"openButton"];
        if (NSNotFound != index)
            [itemIdentifiers insertObject:@"emptyButton" atIndex:index];
        self.emptyButton.enabled = self.emptyButtonEnabled;
    }
    self.touchBar.defaultItemIdentifiers = itemIdentifiers;

    [self
        performSelectorInBackground:@selector(prepareIconsInBackground:)
        withObject:[[urls copy] autorelease]/* be paranoid */];

    return [super presentWithPlacement:placement];
}

- (void)dismiss
{
    self.contents = nil;
    self.url = nil;
    [self.scrubber reloadData];

    [super dismiss];
}

- (void)prepareIconsInBackground:(NSArray<NSURL *> *)urls
{
    @autoreleasepool
    {
        NSMutableDictionary *icons = [NSMutableDictionary dictionary];
        NSSize size = NSMakeSize(60, 60);
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool:YES], kQLThumbnailOptionIconModeKey,
            nil];
        for (NSURL *url in urls)
        {
            NSImage *icon = nil;
            CGImageRef cgimage = QLThumbnailImageCreate(
                0, (CFURLRef)url, size, (CFDictionaryRef)options);
            if (0 != cgimage)
            {
                icon = [[[NSImage alloc] initWithCGImage:cgimage size:NSZeroSize] autorelease];
                CGImageRelease(cgimage);
            }

            if (nil == icon)
                icon = [[NSWorkspace sharedWorkspace] iconForFile:url.path];

            if (nil != icon)
                [icons setObject:icon forKey:url];

            if (0 < icons.count && 0 == icons.count % 4)
            {
                [self
                    performSelectorOnMainThread:@selector(updateIcons:)
                    withObject:[[icons copy] autorelease]
                    waitUntilDone:NO];
                [icons removeAllObjects];
            }
        }

        if (0 < icons.count)
            [self
                performSelectorOnMainThread:@selector(updateIcons:)
                withObject:[[icons copy] autorelease]
                waitUntilDone:NO];
    }
}

- (void)updateIcons:(NSDictionary *)icons
{
    [self.scrubber performSequentialBatchUpdates:^
    {
        NSArray<FolderItem *> *contents = self.contents;
        for (NSURL *url in icons)
        {
            NSUInteger index = 0;
            for (FolderItem *item in contents)
            {
                if ([item.url isEqual:url])
                {
                    item.icon = [icons objectForKey:url];
                    [self.scrubber reloadItemsAtIndexes:[NSIndexSet indexSetWithIndex:index]];
                    break;
                }
                index++;
            }
        }
    }];
}

- (IBAction)emptyButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(folderController:didClick:)])
        [self.delegate folderController:self didClick:@"emptyButton"];
}

- (IBAction)openButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(folderController:didClick:)])
        [self.delegate folderController:self didClick:@"openButton"];
}

- (NSInteger)numberOfItemsForScrubber:(NSScrubber *)scrubber
{
    return self.contents.count;
}

- (NSScrubberItemView *)scrubber:(NSScrubber *)scrubber viewForItemAtIndex:(NSInteger)index
{
    FolderItem *item = [self.contents objectAtIndex:index];
    FolderItemView *view = [self.scrubber makeItemWithIdentifier:@"item" owner:nil];
    view.hidden = NO;
    view.imageTitleView.image = item.icon;
    view.imageTitleView.title = NSImageOnly != self.imagePosition ?
        [item.url lastPathComponent] : @"";
    [view setFrameSize:NSImageOnly != self.imagePosition ? largeItemSize : smallItemSize];
    return view;
}

- (void)scrubber:(NSScrubber *)scrubber didSelectItemAtIndex:(NSInteger)index
{
    if ([self.delegate respondsToSelector:@selector(folderController:didSelectURL:)])
    {
        FolderItem *item = [self.contents objectAtIndex:index];
        [self.delegate folderController:self didSelectURL:item.url];
    }
}
@end
