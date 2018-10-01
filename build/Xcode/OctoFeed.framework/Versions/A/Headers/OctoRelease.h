/**
 * @file OctoFeed/OctoRelease.h
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
 * OctoReleaseState
 */
typedef NS_ENUM(NSUInteger, OctoReleaseState)
{
    /*
     * Release is empty and has not been fetched.
     */
    OctoReleaseEmpty                    = 0,

    /*
     * Release has been fetched: information such as the release version and
     * the release assets is available.
     */
    OctoReleaseFetched                  = 'F',

    /*
     * Release assets have been downloaded and prepared for installation.
     */
    OctoReleaseReadyToInstall           = 'R',

    /*
     * Release has been installed.
     */
    OctoReleaseInstalled                = 'I',
};

typedef void (^OctoReleaseCompletion)(
    NSDictionary<NSURL *, NSURL *> *, NSDictionary<NSURL *, NSError *> *);

/**
 * Encapsulates a single release of a product or project.
 *
 * OctoRelease provides functionality to fetch new and cached releases, download their assets and
 * install them.
 */
@interface OctoRelease : NSObject

/**
 * @method registerClass:
 * Registers a class to handle a specific service.
 *
 * @param service
 *     The service to register this class for. For example, the service "github.com"
 *     is registered by a class that knows how to fetch GitHub releases.
 */
+ (void)registerClass:(NSString *)service;

/**
 * Specifies whether code signatures are required for new releases to be installed.
 *
 * The default is to require signatures and to have those signatures match the signatures
 * of the target bundles.
 */
+ (void)requireCodeSignature:(BOOL)require matchesTarget:(BOOL)matches;

/**
 * The default base directory where cached information for all releases is stored.
 *
 * The default value is a location under ~/Library/Caches.
 */
+ (NSURL *)defaultCacheBaseURL;

/**
 * Returns a release for the specified repository.
 *
 * The new release will have a state of OctoReleaseEmpty until the first fetch call.
 */
+ (OctoRelease *)releaseWithRepository:(NSString *)repository;

/**
 * Returns a release for the specified repository.
 *
 * Allows the specification of multiple target bundles (to update bundles other than the main
 * bundle), a custom URL session or a custom cache location. Specify nil for default values.
 *
 * If you specify a custom URL session you MUST use [NSOperationQueue mainQueue] as its
 * delegateQueue.
 *
 * The new release will have a state of OctoReleaseEmpty until the first fetch call.
 */
+ (OctoRelease *)releaseWithRepository:(NSString *)repository
    targetBundles:(NSArray<NSBundle *> *)bundles
    session:(NSURLSession *)session
    cacheBaseURL:(NSURL *)cacheBaseURL;

/**
 * Initializes a release for the specified repository.
 *
 * The new release will have a state of OctoReleaseEmpty until the first fetch call.
 */
- (id)initWithRepository:(NSString *)repository;

/**
 * Initializes a release for the specified repository.
 *
 * Allows the specification of multiple target bundles (to update bundles other than the main
 * bundle), a custom URL session or a custom cache location. Specify nil for default values.
 *
 * If you specify a custom URL session you MUST use [NSOperationQueue mainQueue] as its
 * delegateQueue.
 *
 * The new release will have a state of OctoReleaseEmpty until the first fetch call.
 */
- (id)initWithRepository:(NSString *)repository
    targetBundles:(NSArray<NSBundle *> *)bundles
    session:(NSURLSession *)session
    cacheBaseURL:(NSURL *)cacheBaseURL;

/**
 * Cancels any asynchronous operations.
 */
- (void)cancel;

/**
 * Fetches information about a release. This is an asynchronous call.
 *
 * Depending on the repository associated with this release, this call may fetch information
 * from a remote location or from the local cache if any. If information is successfully fetched
 * the state of this instance will change to OctoReleaseFetched.
 *
 * Subclasses of this class may override this call to implement support for additional remote
 * repositories.
 */
- (void)fetch:(void (^)(NSError *))completion;

/**
 * Fetches information about a release synchronously.
 *
 * Only cached release objects (i.e. those created with an empty repository ("")) support this call.
 * Other release objects will return NO.
 *
 * If information is successfully fetched the state of this instance will change to
 * OctoReleaseFetched.
 */
- (BOOL)fetchSynchronouslyIfAble:(NSError **)errorp;

/**
 * Prepare assets associated with a release for installation. This is an asynchronous call.
 *
 * The state of the release prior to this call must be OctoReleaseFetched. If all assets are
 * successfully downloaded and prepared the state of this instance will change to
 * OctoReleaseReadyToInstall.
 */
- (void)prepareAssets:(OctoReleaseCompletion)completion;

/**
 * Installs assets associated with a release. This is a synchronous call.
 *
 * The state of the release prior to this call must be OctoReleaseReadyToInstall. If all assets are
 * successfully installed the state of this instance will change to OctoReleaseInstalled.
 *
 * If this call is used to update the main bundle, the application should be relaunched ASAP.
 */
- (void)installAssetsSynchronously:(OctoReleaseCompletion)completion;

/**
 * Clears any cached information (downloaded files, etc.) and resets the release state to
 * OctoReleaseEmpty.
 */
- (NSError *)clear;

/**
 * The repository to check for new releases.
 */
- (NSString *)repository;

/**
 * The bundles that can be updated by a new release.
 *
 * It is possible to update multiple bundles with a single release.
 */
- (NSArray<NSBundle *> *)targetBundles;

/**
 * The base directory where cached information for all releases is stored.
 */
- (NSURL *)cacheBaseURL;

/**
 * The base directory where cached information for this release is stored.
 */
- (NSURL *)cacheURL;

/**
 * The URL sesssion used for downloading releases.
 */
- (NSURLSession *)session;

/**
 * The version of this release.
 * Valid after a successful call to fetch: or fetchSynchronouslyIfAble:.
 */
- (NSString *)releaseVersion;

/**
 * Flag that determines whether this is a "pre-release".
 * Valid after a successful call to fetch: or fetchSynchronouslyIfAble:.
 */
- (BOOL)prerelease;

/**
 * Assets associated with a release.
 * Valid after a successful call to fetch: or fetchSynchronouslyIfAble:.
 */
- (NSArray<NSURL *> *)releaseAssets;

/**
 * Prepared assets associated with a release.
 * Valid after a successful call to prepareAssets:.
 */
- (NSArray<NSURL *> *)preparedAssets;

/**
 * Release state.
 */
- (OctoReleaseState)state;

/**
 * Overall progress.
 */
- (NSProgress *)progress;

/**
 * Overall progress value as a number between 0 and 1.
 *
 * Posts KVO notifications in the main thread and is appropriate for use in UI elements.
 */
- (double)progressValue;

/**
 * Commits (writes) the current release state to the cache.
 */
- (NSError *)commit;
@end

/**
 * Provides extensions useful to OctoRelease subclasses.
 */
@interface OctoRelease (Extensions)

/**
 * Backing property for releaseVersion.
 */
@property (copy) NSString *_releaseVersion;

/**
 * Backing property for prerelease.
 */
@property (assign) BOOL _prerelease;

/**
 * Backing property for releaseAssets.
 */
@property (copy) NSArray<NSURL *> *_releaseAssets;

/**
 * Backing property for preparedAssets.
 */
@property (copy) NSArray<NSURL *> *_preparedAssets;

/**
 * Backing property for state.
 */
@property (assign) OctoReleaseState _state;

/**
 * Backing property for progress.
 */
@property (retain) NSProgress *_progress;
@end
