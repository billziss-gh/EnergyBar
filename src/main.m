/**
 * @file main.m
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

#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSMutableDictionary *defaults = [NSMutableDictionary
        dictionaryWithContentsOfFile:[[NSBundle mainBundle]
        pathForResource:@"defaults"
        ofType:@"plist"]];
    [defaults
        setObject:[[defaults objectForKey:@"defaultAppsFolder"] stringByExpandingTildeInPath]
        forKey:@"defaultAppsFolder"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    [[NSFileManager defaultManager]
        createDirectoryAtPath:[defaults objectForKey:@"defaultAppsFolder"]
        withIntermediateDirectories:YES
        attributes:nil
        error:nil];

    [pool release];

    return NSApplicationMain(argc, argv);
}
