#import <UIKit/UIKit.h>
#import "Utilities/Button/BeaButton.h"
#import "BeFake/TokenManager/BeaTokenManager.h"
#import "BeFake/ViewControllers/UploadViewController/BeaUploadViewController.h"

#ifdef JAILED
#import "fishhook/fishhook.h"
#endif

// Version info for BeReal 4.58.0 compatibility
#define TWEAK_VERSION @"0.3.0"
#define BEREAL_MIN_VERSION @"4.58.0"

NSDictionary *headers;

// ============================================
// ADVERTISEMENT CLASSES
// ============================================

@interface AdvertsDataNativeViewContainer : UIView
@end

// ============================================
// JAILBREAK DETECTION CLASSES
// ============================================

@interface PAGDeviceHelper : NSObject
+ (BOOL)bu_isJailBroken;
+ (BOOL)isJailBroken;
@end

@interface STKDevice : NSObject
+ (BOOL)containsJailbrokenFiles;
+ (BOOL)containsJailbrokenPermissions;
+ (BOOL)isJailbroken;
+ (BOOL)isDebug;
@end

// BeReal 4.58.0 - JailbreakCheck class
@interface BeaJailbreakCheck : NSObject
- (BOOL)isJailbroken;
+ (BOOL)isJailbroken;
- (BOOL)check;
+ (BOOL)check;
- (BOOL)isJailbreak;
+ (BOOL)isJailbreak;
@end

// Shake SDK
@interface SHKDeviceInfo : NSObject
+ (BOOL)isJailbroken;
- (BOOL)isJailbroken;
@end

// Adjust SDK
@interface ADJDeviceInfo : NSObject
- (BOOL)isJailBroken;
+ (BOOL)isJailBroken;
@end

// Google Ads SDK
@interface GADDeviceInfo : NSObject
- (BOOL)isJailbroken;
@end

// Meta Ads SDK
@interface FBAdUtility : NSObject
+ (BOOL)isJailbroken;
@end

// ============================================
// VIEW CONTROLLER CLASSES
// ============================================

// BeReal 4.58.0 - New HomeViewHostingController
@interface HomeViewHostingController : UIViewController
- (void)setupUploadButton;
- (void)handleUploadTap;
- (UIImageView *)findLogoImageViewInView:(UIView *)view;
@end

// Legacy HomeViewController for older versions
@interface HomeViewController : UIViewController
@property (nonatomic, retain) UIImageView *ibNavBarLogoImageView;
- (void)showVersionAlert;
@end

// ============================================
// MEDIA VIEW CLASSES
// ============================================

@interface CAFilter : NSObject
@property (copy) NSString *name;
@end

// BeReal 4.58.0 - SwiftUI _UIHostingView for media
@interface MediaViewHosting : UIView
@property (nonatomic, strong) BeaButton *downloadButton;
@end

// BeReal 4.58.0 - New DoubleMediaViewUIKitLegacyImpl from RealComponents
@interface DoubleMediaViewUIKitLegacyImpl : UIView
@property (nonatomic, strong) BeaButton *downloadButton;
@property (nonatomic, strong) UIImageView *primaryImageView;
@property (nonatomic, strong) UIImageView *secondaryImageView;
@end

// Legacy MediaView for older versions
@interface MediaView : UIView
@property (nonatomic, strong) BeaButton *downloadButton;
@end

// Legacy DoubleMediaView
@interface DoubleMediaView : UIView
@end

// Legacy DoubleMediaView SwiftUI (for user interaction)
@interface DoubleMediaViewLegacy : UIView
- (NSString *)accessibilityIdentifier;
@end

// ============================================
// BLUR STATE CLASSES
// ============================================

// BeReal 4.58.0 - BlurStateUseCaseImpl controls post blur state
@interface BlurStateUseCaseImpl : NSObject
- (BOOL)isBlurred;
- (BOOL)isBlurredState;
- (id)blurState;
@end

// BeReal 4.58.0 - AdvertNativeViewContainer
@interface AdvertNativeViewContainer : UIView
@end