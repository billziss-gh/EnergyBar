/**
 * @file FolderController.m
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

#import "FolderController.h"
#import "ImageTitleView.h"

static NSSize smallItemSize = { 50, 30 };
static NSSize largeItemSize = { 150, 30 };

@interface FolderItem : NSObject
@property (retain) NSString *name;
@property (retain) NSImage *icon;
@end

@implementation FolderItem
- (void)dealloc
{
    self.name = nil;
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
    self.imageTitleView.titleFont = [NSFont
        systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]];
    self.imageTitleView.titleLineBreakMode = NSLineBreakByTruncatingTail;
    [self addSubview:self.imageTitleView];

    return self;
}

- (void)dealloc
{
    self.imageTitleView = nil;

    [super dealloc];
}
@end

@interface FolderController ()
@property (retain) IBOutlet NSScrubber *scrubber;
@property (retain) IBOutlet NSTextField *label;
@property (retain) IBOutlet NSButton *emptyButton;
@property (retain) IBOutlet NSButton *openButton;
@property (retain) NSArray *contents;
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
            [NSArray arrayWithObject:self.sortKey] : nil
        options:
            (self.includeDescendants ? 0 : NSDirectoryEnumerationSkipsSubdirectoryDescendants) |
            NSDirectoryEnumerationSkipsPackageDescendants |
            NSDirectoryEnumerationSkipsHiddenFiles
        errorHandler:nil];
    NSMutableArray *contents = [NSMutableArray array];
    BOOL tooManyItems = NO;
    NSURL *url;
    while (0 != (url = [enumerator nextObject]))
    {
        if (100 <= contents.count)
        {
            tooManyItems = YES;
            break;
        }
        [contents addObject:url];
    }
    [contents sortUsingComparator:^NSComparisonResult(id obj1, id obj2)
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

    return [super presentWithPlacement:placement];
}

- (void)dismiss
{
    self.contents = nil;
    self.url = nil;

    [super dismiss];
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
    NSURL *url = [self.contents objectAtIndex:index];
    FolderItemView *view = [self.scrubber makeItemWithIdentifier:@"item" owner:nil];
    view.imageTitleView.image = [[NSWorkspace sharedWorkspace] iconForFile:url.path];
    view.imageTitleView.title = NSImageOnly != self.imagePosition ? [url.path lastPathComponent] : @"";
    [view setFrameSize:NSImageOnly != self.imagePosition ? largeItemSize : smallItemSize];
    return view;
}

- (void)scrubber:(NSScrubber *)scrubber didSelectItemAtIndex:(NSInteger)index
{
    if ([self.delegate respondsToSelector:@selector(folderController:didSelectURL:)])
    {
        NSURL *url = [self.contents objectAtIndex:index];
        [self.delegate folderController:self didSelectURL:url];
    }
}
@end

#if 0
static NSSize iconSize = { 30, 30 };
static CGFloat spacerWidth = 4;

@implementation DockWidgetFolderController


@end
#endif

