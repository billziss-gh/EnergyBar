/**
 * @file OctoFeed/OctoExtractor.h
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

@interface OctoExtractor : NSObject
+ (BOOL)canExtractURL:(NSURL *)url;
+ (void)extractURL:(NSURL *)src
    toURL:(NSURL *)dst
    completion:(void (^)(NSError *error))completion;
- (id)initWithURL:(NSURL *)url;
- (void)extractToURL:(NSURL *)dst
    completion:(void (^)(NSError *error))completion;
@end
