/**
 * @file OctoFeed/NSTask+Relaunch.h
 *
 * @copyright 2018 Bill Zissimopoulos
 */
/*
 * This file is part of OctoFeed.
 *
 * It is licensed under the MIT license. The full license text can be found
 * in the License.txt file at the root of this project.
 */

#import <Foundation/Foundation.h>

/**
 * Provides methods to relaunch the currently running application.
 */
@interface NSTask (Relaunch)

/**
 * Relaunches the currently running application.
 */
+ (void)relaunch;

/**
 * Relaunches the currently running application with the specified path.
 */
+ (void)relaunchWithPath:(NSString *)path;

/**
 * Relaunches the currently running application with the specified URL.
 */
+ (void)relaunchWithURL:(NSURL *)url;
@end
