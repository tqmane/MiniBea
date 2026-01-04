#import "Tweak.h"
#import <objc/runtime.h>

static UIButton *beaUploadButton;
static char kDownloadButtonKey;
static char kNavUploadItemKey;

static Class BeaClassFromNames(NSArray<NSString *> *candidates) {
	for (NSString *name in candidates) {
		Class cls = objc_getClass(name.UTF8String);
		if (cls) return cls;
	}
	return Nil;
}

static UIWindow *BeaActiveWindow(void) {
	UIApplication *app = [UIApplication sharedApplication];
	for (UIWindow *window in app.windows) {
		if (window.isKeyWindow) {
			return window;
		}
	}

	for (UIWindow *window in app.windows) {
		if (!window.isHidden) {
			return window;
		}
	}

	return app.windows.firstObject;
}

static UIViewController *BeaTopViewController(void) {
	UIWindow *window = BeaActiveWindow();
	if (!window) return nil;

	UIViewController *root = window.rootViewController;
	while (root) {
		if ([root isKindOfClass:[UINavigationController class]]) {
			UINavigationController *nav = (UINavigationController *)root;
			if (nav.visibleViewController) {
				root = nav.visibleViewController;
				continue;
			}
		}

		if ([root isKindOfClass:[UITabBarController class]]) {
			UITabBarController *tab = (UITabBarController *)root;
			if (tab.selectedViewController) {
				root = tab.selectedViewController;
				continue;
			}
		}

		if (root.presentedViewController) {
			root = root.presentedViewController;
			continue;
		}
		break;
	}
	return root;
}

@interface BeaUploadLauncher : NSObject
@end

@implementation BeaUploadLauncher
+ (void)presentUpload {
	if (![[BeaTokenManager sharedInstance] BRAccessToken]) return;

	dispatch_async(dispatch_get_main_queue(), ^{
		UIViewController *top = BeaTopViewController();
		if (!top) return;

		BeaUploadViewController *beaUploadViewController = [[BeaUploadViewController alloc] init];
		beaUploadViewController.modalPresentationStyle = UIModalPresentationFullScreen;
		[top presentViewController:beaUploadViewController animated:YES completion:nil];
	});
}
@end

static void BeaEnsureUploadButton(void) {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIWindow *window = BeaActiveWindow();
		UIViewController *top = BeaTopViewController();

		BOOL attachedToNav = NO;
		if (top && top.navigationController) {
			UIBarButtonItem *item = objc_getAssociatedObject(top, &kNavUploadItemKey);
			if (!item) {
				UIButton *navButton = [UIButton buttonWithType:UIButtonTypeSystem];
				navButton.translatesAutoresizingMaskIntoConstraints = NO;
				navButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.15];
				navButton.layer.cornerRadius = 16.0;
				navButton.layer.masksToBounds = YES;

				UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightBold];
				UIImage *plusImage = [UIImage systemImageNamed:@"plus.circle.fill" withConfiguration:config];
				plusImage = [plusImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
				navButton.tintColor = [UIColor whiteColor];
				[navButton setImage:plusImage forState:UIControlStateNormal];
				[navButton.widthAnchor constraintEqualToConstant:32].active = YES;
				[navButton.heightAnchor constraintEqualToConstant:32].active = YES;
				[navButton addTarget:[BeaUploadLauncher class] action:@selector(presentUpload) forControlEvents:UIControlEventTouchUpInside];

				item = [[UIBarButtonItem alloc] initWithCustomView:navButton];
				objc_setAssociatedObject(top, &kNavUploadItemKey, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
			}

			NSMutableArray *items = top.navigationItem.rightBarButtonItems.mutableCopy ?: [NSMutableArray array];
			if (![items containsObject:item]) {
				[items addObject:item];
				top.navigationItem.rightBarButtonItems = items;
			}
			attachedToNav = YES;
		}

		if (attachedToNav) {
			if (beaUploadButton && beaUploadButton.superview) {
				[beaUploadButton removeFromSuperview];
			}
			return;
		}

		if (!window) return;

		if (!beaUploadButton) {
			beaUploadButton = [UIButton buttonWithType:UIButtonTypeCustom];
			beaUploadButton.translatesAutoresizingMaskIntoConstraints = NO;
			beaUploadButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
			beaUploadButton.layer.cornerRadius = 18.0;
			beaUploadButton.layer.masksToBounds = YES;
			beaUploadButton.layer.zPosition = 120;

			UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightBold];
			UIImage *plusImage = [UIImage systemImageNamed:@"plus.circle.fill" withConfiguration:config];
			beaUploadButton.tintColor = [UIColor whiteColor];
			[beaUploadButton setImage:plusImage forState:UIControlStateNormal];
			[beaUploadButton addTarget:[BeaUploadLauncher class] action:@selector(presentUpload) forControlEvents:UIControlEventTouchUpInside];
		}

		if (beaUploadButton.superview != window) {
			[window addSubview:beaUploadButton];
			[NSLayoutConstraint activateConstraints:@[
				[beaUploadButton.widthAnchor constraintEqualToConstant:36],
				[beaUploadButton.heightAnchor constraintEqualToConstant:36],
				[beaUploadButton.centerXAnchor constraintEqualToAnchor:window.centerXAnchor constant:88],
				[beaUploadButton.topAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.topAnchor constant:8]
			]];
		}
		[window bringSubviewToFront:beaUploadButton];
	});
}

static void BeaEnsureDownloadButtonOnView(UIView *view) {
	if (!view) return;

	BeaButton *button = objc_getAssociatedObject(view, &kDownloadButtonKey);
	if (!button) {
		button = [BeaButton downloadButton];
		objc_setAssociatedObject(view, &kDownloadButtonKey, button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

		[view addSubview:button];
		[NSLayoutConstraint activateConstraints:@[
			[button.trailingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.trailingAnchor constant:-12.0],
			[button.topAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.topAnchor constant:12.0]
		]];
	}
	[view bringSubviewToFront:button];
}

static void BeaRemoveAdView(UIView *view) {
	if (!view) return;
	view.hidden = YES;
	view.alpha = 0.0f;
	dispatch_async(dispatch_get_main_queue(), ^{
		[view removeFromSuperview];
	});
}

%hook PAGDeviceHelper
+ (BOOL)bu_isJailBroken {
	return NO;
}
%end

%hook STKDevice
+ (BOOL)containsJailbrokenFiles {
	return NO;
}

+ (BOOL)containsJailbrokenPermissions {
	return NO;
}

+ (BOOL)isJailbroken {
	return NO;
}
%end

%hook NSMutableURLRequest
- (void)setAllHTTPHeaderFields:(NSDictionary *)arg1 {
	%orig;

	if (!headers && [[arg1 allKeys] containsObject:@"Authorization"] && [[arg1 allKeys] containsObject:@"bereal-device-id"]) {
		if ([arg1[@"Authorization"] length] > 0) {
			headers = (NSDictionary *)arg1;
			[[BeaTokenManager sharedInstance] setHeaders:headers];
		}
	}
}
%end

%hook CAFilter
- (void)setValue:(id)arg1 forKey:(id)arg2 {
	// remove the blur that gets applied to the BeReals
	// this is kind of a fallback if the normal unblur function somehow fails (BeReal 2.0+)

	if (([arg1 isEqual:@(13)] || [arg1 isEqual:@(8)]) && [self.name isEqual:@"gaussianBlur"]) {
		return %orig(0, arg2);
	}
	%orig;
}
%end

%hook DoubleMediaViewUIKitLegacyImpl
%property (nonatomic, strong) BeaButton *downloadButton;

- (void)layoutSubviews {
	%orig;
	BeaEnsureDownloadButtonOnView(self);
}
%end

%hook LightWeightDoubleMediaView
- (void)layoutSubviews {
	%orig;
	BeaEnsureDownloadButtonOnView(self);
}
%end

%hook LegacyDoubleMediaView
- (void)layoutSubviews {
	%orig;
	BeaEnsureDownloadButtonOnView(self);
}
%end

%hook UIViewController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
	// BeReal somehow shows an error alert when using this tweak (at least on my device), so remove it
	if ([viewControllerToPresent isKindOfClass:[UIAlertController class]]) {
		UIAlertController *alert = (UIAlertController *)viewControllerToPresent;
		if ([alert.message isEqualToString:@"[\"Unable to load contents\"]"]) {
			return;
		}
	}
	%orig;
}

- (void)viewDidAppear:(BOOL)animated {
	%orig;
	BeaEnsureUploadButton();
}
%end

BOOL isBlockedPath(const char *path) {
	if (!path) return NO;

	NSString *pathStr = @(path);

	if ([pathStr hasPrefix:@"/var/jb/"] ||
		[pathStr hasPrefix:@"/private/preboot/"] ||
		[pathStr hasPrefix:@"/private/var/jb"] ||
		[pathStr hasPrefix:@"/private/var/lib/apt"] ||
		[pathStr hasPrefix:@"/private/var/lib/cydia"] ||
		[pathStr hasPrefix:@"/private/var/stash"] ||
		[pathStr hasPrefix:@"/private/var/tmp/cydia"]) {
		return YES;
	}

	NSArray *jbPaths = @[
		@"/Applications/Cydia.app",
		@"/Library/MobileSubstrate/MobileSubstrate.dylib",
		@"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
		@"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
		@"/bin/bash",
		@"/etc/apt",
		@"/usr/bin/sshd",
		@"/usr/libexec/sftp-server",
		@"/usr/sbin/sshd"
	];

	for (NSString *jbPath in jbPaths) {
		if ([pathStr isEqualToString:jbPath]) {
			return YES;
		}
	}

	return NO;
}

%hook NSFileManager
- (BOOL)fileExistsAtPath:(NSString *)path {
	if (isBlockedPath([path UTF8String])) {
		return NO;
	}
	return %orig;
}
%end

%hook AdvertsDataNativeViewContainer
- (void)didMoveToSuperview {
	%orig;
	BeaRemoveAdView(self);
}

- (CGSize)sizeThatFits:(CGSize)size {
	return CGSizeZero;
}

- (CGSize)intrinsicContentSize {
	return CGSizeZero;
}
%end

%hook AdvertView
- (void)didMoveToSuperview {
	%orig;
	BeaRemoveAdView(self);
}
%end

%hook AppLovinNativeView
- (void)didMoveToSuperview {
	%orig;
	BeaRemoveAdView(self);
}
%end

%hook AppLovinBottomNativeView16x9
- (void)didMoveToSuperview {
	%orig;
	BeaRemoveAdView(self);
}
%end

%hook AppLovinDefaultNativeView16x9
- (void)didMoveToSuperview {
	%orig;
	BeaRemoveAdView(self);
}
%end

%hook AppLovinBottomNativeView
- (void)didMoveToSuperview {
	%orig;
	BeaRemoveAdView(self);
}
%end

%hook AppLovinPartnerFeedNativeView16x9
- (void)didMoveToSuperview {
	%orig;
	BeaRemoveAdView(self);
}
%end

%hook AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	BOOL result = %orig;

	[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
		BeaEnsureUploadButton();
	}];
	[[NSNotificationCenter defaultCenter] addObserverForName:UIWindowDidBecomeKeyNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(__unused NSNotification *note) {
		BeaEnsureUploadButton();
	}];

	BeaEnsureUploadButton();
	return result;
}
%end

%ctor {
	Class mediaViewClass = BeaClassFromNames(@[@"_TtC14RealComponents30DoubleMediaViewUIKitLegacyImpl", @"_TtGC7SwiftUI14_UIHostingViewVS_14_ViewList_View_", @"DoubleMediaViewUIKitLegacyImpl"]);
	Class lightWeightClass = BeaClassFromNames(@[@"LightWeightDoubleMediaView", @"_TtC6BeReal22LightWeightDoubleMediaView"]);
	Class legacyMediaClass = BeaClassFromNames(@[@"LegacyDoubleMediaView", @"_TtC6BeReal19LegacyDoubleMediaView"]);
	Class advertsViewClass = BeaClassFromNames(@[@"_TtC11AdvertsData25AdvertNativeViewContainer", @"AdvertsData.AdvertNativeViewContainer", @"AdvertNativeViewContainer"]);
	Class appDelegateClass = BeaClassFromNames(@[@"_TtC6BeReal11AppDelegate"]);

	%init(
	  DoubleMediaViewUIKitLegacyImpl = mediaViewClass,
	  LightWeightDoubleMediaView = lightWeightClass,
	  LegacyDoubleMediaView = legacyMediaClass,
	  AdvertsDataNativeViewContainer = advertsViewClass,
	  AppDelegate = appDelegateClass
	);
}
