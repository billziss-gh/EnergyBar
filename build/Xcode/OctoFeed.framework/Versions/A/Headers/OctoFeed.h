/**
 * @file OctoFeed/OctoFeed.h
 *
 * OctoFeed provides functionality for easily updating macOS applications. This functionality
 * includes checking for new releases, downloading them and installing them. It also includes
 * lower-level functionality such as relauncing an application.
 *
 * The main 2 classes in this framework are OctoFeed and OctoRelease.
 * <ul>
 * <li>OctoFeed acts as an orchestrator and manages the overall process of updating
 * an application. Usually there is a single OctoFeed instance (accessible using
 * +mainBundleFeed) that manages updates for the main bundle.</li>
 * <li>OctoRelease encapsulates a single release and provides functionality to fetch releases,
 * download their assets and install them.
 * </ul>
 *
 * At a minimum the following steps are required to enable automatic updates for an application:
 * <ul>
 * <li>Add an "OctoRepository" key to your Info.plist pointing to your GitHub repository
 * (e.g. github.com/billziss-gh/OctoFeed).
 * </li>
 * <li>Add the following code in your applicationDidFinishLaunching: method. Either:
 * <pre>
 * [[OctoFeed mainBundleFeed] activateWithInstallPolicy:OctoFeedInstallAtActivation];
 * </pre>
 * Or:
 * <pre>
 * [[OctoFeed mainBundleFeed] activateWithInstallPolicy:OctoFeedInstallAtQuit];
 * </pre>
 * The code you choose depends on whether you want update installation to happen during launch
 * time or quit time. It is also possible to have more control over the installation by using
 * a different policy.
 * </li>
 * </ul>
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
#import <OctoFeed/NSString+Version.h>
#import <OctoFeed/NSTask+Relaunch.h>
#import <OctoFeed/OctoError.h>
#import <OctoFeed/OctoExtractor.h>
#import <OctoFeed/OctoRelease.h>
#import <OctoFeed/OctoVerifier.h>

/**
 * OctoFeedInstallPolicy
 */
typedef NS_ENUM(NSUInteger, OctoFeedInstallPolicy)
{
    /*
     * Releases will be checked, but no installation will be performed.
     */
    OctoFeedInstallNone                 = 0,

    /*
     * Releases will be downloaded and prepared for installation.
     * During activation a release will be installed if it is ready to install.
     */
    OctoFeedInstallAtActivation         = 'A',

    /*
     * Releases will be downloaded and prepared for installation.
     * During app termination a release will be installed if it is ready to install.
     */
    OctoFeedInstallAtQuit               = 'Q',

    /*
     * Releases will be downloaded and prepared for installation.
     * When the release is ready to install, a notification will be posted to allow
     * the application to initiate an install if it so chooses.
     */
    OctoFeedInstallWhenReady            = 'R',
};

typedef void (^OctoFeedCompletion)(OctoRelease *, NSError *);

/**
 * Manages the overall update process.
 *
 * OctoFeed checks for new releases, downloads them and installs them according
 * to specified policy.
 */
@interface OctoFeed : NSObject

/**
 * Returns the default OctoFeed instance, which manages updates for the main bundle.
 *
 * The bundle must contain an "OctoRepository" key that points to the repository to check for
 * new releases. For example, this project's own repository would be specified as
 * "github.com/billziss-gh/OctoFeed."
 */
+ (OctoFeed *)mainBundleFeed;

/**
 * Initializes an OctoFeed instance to manage updates for the specified bundle.
 *
 * The bundle must contain an "OctoRepository" key that points to the repository to check for
 * new releases. For example, this project's own repository would be specified as
 * "github.com/billziss-gh/OctoFeed."
 */
- (id)initWithBundle:(NSBundle *)bundle;

/**
 * Activates this instance with the specified install policy.
 *
 * Depending on the policy the instance will check for new releases, download them,
 * extract them and install them.
 *
 * @param policy
 *     The install policy to use when activated.
 * @return
 *     YES on success; NO on failure.
 */
- (BOOL)activateWithInstallPolicy:(OctoFeedInstallPolicy)policy;

/**
 * Deactivates this instance.
 */
- (void)deactivate;

/**
 * Initiates a check for new releases.
 */
- (void)check:(OctoFeedCompletion)completion;

/**
 * Returns the current release, if any.
 *
 * When OctoFeed finds a new release, this method returns non-nil.
 */
- (OctoRelease *)currentRelease;

/**
 * Clears any cached information (downloaded files, etc.) for the specified release and
 * any releases with earlier versions.
 *
 * @param release
 *     The release to clear.
 * @return
 *     Returns nil on success; NSError on failure.
 */
- (NSError *)clearThisAndPriorReleases:(OctoRelease *)release;

/**
 * The repository to check for new releases.
 *
 * For example, this project's own repository would be specified as
 * "github.com/billziss-gh/OctoFeed."
 */
@property (copy) NSString *repository;

/**
 * How often to perform a release check.
 */
@property (assign) NSTimeInterval checkPeriod;

/**
 * The bundles that can be updated by a new release.
 *
 * Normally this array contains only the main bundle.
 */
@property (copy) NSArray<NSBundle *> *targetBundles;

/**
 * A URL sesssion to use for downloading releases.
 *
 * If a custom session is assigned, it MUST use [NSOperationQueue mainQueue] as its delegateQueue.
 */
@property (retain) NSURLSession *session;

/**
 * The base directory where cached information for all releases is stored.
 *
 * The default value is a location under ~/Library/Caches.
 */
@property (copy) NSURL *cacheBaseURL;
@end

/**
 * Notification posted whenever the state of a release changes.
 *
 * The notification object is the OctoFeed instance posting the notification.
 * The userInfo dictionary contains an OctoNotificationReleaseKey that points
 * to the corresponding release and an OctoNotificationReleaseStateKey that points
 * to the release state at the time of posting.
 */
extern NSString *OctoNotification;
extern NSString *OctoNotificationReleaseKey;
extern NSString *OctoNotificationReleaseStateKey;

/**
 * Bundle key that points to the repository to check for new releases.
 *
 * For example, this project's own repository would be specified as
 * "github.com/billziss-gh/OctoFeed."
 */
extern NSString *OctoRepositoryKey;
extern NSString *OctoCheckPeriodKey;

extern NSString *OctoLastCheckTimeKey;
