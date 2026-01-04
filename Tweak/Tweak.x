#import "Tweak.h"
#import <objc/runtime.h>

static UIButton *beaUploadButton;

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
		if (!window) return;

		if (!beaUploadButton) {
			beaUploadButton = [UIButton buttonWithType:UIButtonTypeCustom];
			beaUploadButton.translatesAutoresizingMaskIntoConstraints = NO;
			beaUploadButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
			beaUploadButton.layer.cornerRadius = 20.0;
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
				[beaUploadButton.widthAnchor constraintEqualToConstant:40],
				[beaUploadButton.heightAnchor constraintEqualToConstant:40],
				[beaUploadButton.trailingAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.trailingAnchor constant:-14],
				[beaUploadButton.topAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.topAnchor constant:14]
			]];
		}
		[window bringSubviewToFront:beaUploadButton];
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

	if (![self downloadButton]) {
		BeaButton *downloadButton = [BeaButton downloadButton];
		downloadButton.layer.zPosition = 99;

		[self setDownloadButton:downloadButton];
		[self addSubview:downloadButton];

		[NSLayoutConstraint activateConstraints:@[
			[[[self downloadButton] trailingAnchor] constraintEqualToAnchor:[self trailingAnchor] constant:-12.0],
			[[[self downloadButton] topAnchor] constraintEqualToAnchor:[self topAnchor] constant:12.0]
		]];
	}
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
	[self removeFromSuperview];
}

- (CGSize)sizeThatFits:(CGSize)size {
	return CGSizeZero;
}

- (CGSize)intrinsicContentSize {
	return CGSizeZero;
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
	Class mediaViewClass = BeaClassFromNames(@[@"_TtC14RealComponents30DoubleMediaViewUIKitLegacyImpl", @"_TtGC7SwiftUI14_UIHostingViewVS_14_ViewList_View_"]);
	Class advertsViewClass = BeaClassFromNames(@[@"_TtC11AdvertsData25AdvertNativeViewContainer", @"AdvertsData.AdvertNativeViewContainer"]);
	Class appDelegateClass = BeaClassFromNames(@[@"_TtC6BeReal11AppDelegate"]);

	%init(
	  DoubleMediaViewUIKitLegacyImpl = mediaViewClass,
	  AdvertsDataNativeViewContainer = advertsViewClass,
	  AppDelegate = appDelegateClass
	);
}
