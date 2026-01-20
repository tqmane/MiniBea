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

// BeReal 4.58.0 - JailbreakCheck class (Swift mangled name)
@interface _TtC6BeReal14JailbreakCheck : NSObject
- (BOOL)isJailbroken;
+ (BOOL)isJailbroken;
- (BOOL)check;
+ (BOOL)check;
- (BOOL)isJailbreak;
+ (BOOL)isJailbreak;
@end

// Legacy JailbreakCheck interface
@interface JailbreakCheck : NSObject
- (BOOL)isJailbroken;
+ (BOOL)isJailbroken;
- (BOOL)check;
+ (BOOL)check;
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

// BeReal 4.58.0 - New HomeViewHostingController (Swift mangled name)
@interface _TtC6BeReal25HomeViewHostingController : UIViewController
- (void)setupUploadButton;
- (void)handleUploadTap;
- (UIView *)view;
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

// BeReal 4.58.0 - SwiftUI _UIHostingView (Swift mangled name)
@interface _TtGC7SwiftUI14_UIHostingViewVS_14_ViewList_View_ : UIView
@property (nonatomic, strong) BeaButton *downloadButton;
- (NSArray *)subviews;
@end

// BeReal 4.58.0 - New DoubleMediaViewUIKitLegacyImpl from RealComponents (Swift mangled name)
@interface _TtC14RealComponents30DoubleMediaViewUIKitLegacyImpl : UIView
@property (nonatomic, strong) BeaButton *downloadButton;
@property (nonatomic, strong) UIImageView *primaryImageView;
@property (nonatomic, strong) UIImageView *secondaryImageView;
- (NSArray *)subviews;
@end

// Legacy MediaView for older versions
@interface MediaView : UIView
@property (nonatomic, strong) BeaButton *downloadButton;
@end

// Legacy DoubleMediaView
@interface DoubleMediaView : UIView
@end

// ============================================
// BLUR STATE CLASSES
// ============================================

// BeReal 4.58.0 - BlurStateUseCaseImpl controls post blur state (Swift mangled name)
@interface _TtC18FeedsFeatureDomain20BlurStateUseCaseImpl : NSObject
- (BOOL)isBlurred;
- (BOOL)isBlurredState;
- (id)blurState;
@end

// Legacy BlurStateUseCaseImpl
@interface BlurStateUseCaseImpl : NSObject
- (BOOL)isBlurred;
- (BOOL)isBlurredState;
- (id)blurState;
@end