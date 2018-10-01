/**
 * @file OctoFeed/OctoVerifier.h
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

@interface OctoVerifier : NSObject
+ (NSError *)verifyCodeSignatureAtURL:(NSURL *)src matchesCodesSignatureAtURL:(NSURL *)dst;
- (id)initWithURL:(NSURL *)url;
- (NSError *)verifyCodeSignatureMatchesCodeSignatureAtURL:(NSURL *)url;
@end
