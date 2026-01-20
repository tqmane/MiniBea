#import "Tweak.h"
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

// ============================================
// GLOBAL ASSOCIATED OBJECT KEYS
// ============================================
static char kMinibeaDownloadButtonKey;
static char kMinibeaCheckedKey;

// ============================================
// JAILBREAK DETECTION BYPASS - BeReal 4.58.0
// ============================================

// ByteDance/Pangle Ads SDK
%hook PAGDeviceHelper
+ (BOOL)bu_isJailBroken {
	return NO;
}
+ (BOOL)isJailBroken {
	return NO;
}
%end

// StackModules SDK (Appodeal)
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

+ (BOOL)isDebug {
	return NO;
}
%end

// Shake SDK jailbreak detection
%hook SHKDeviceInfo
+ (BOOL)isJailbroken {
	return NO;
}
- (BOOL)isJailbroken {
	return NO;
}
%end

// Generic UIDevice extension hooks
%hook UIDevice
- (BOOL)isJailbroken {
	return NO;
}
%end

// Adjust SDK (if it checks for jailbreak)
%hook ADJDeviceInfo
- (BOOL)isJailBroken {
	return NO;
}
+ (BOOL)isJailBroken {
	return NO;
}
%end

// Firebase/Google Ads related
%hook GADDeviceInfo  
- (BOOL)isJailbroken {
	return NO;
}
%end

// FBAudienceNetwork (Meta Ads)
%hook FBAdUtility
+ (BOOL)isJailbroken {
	return NO;
}
%end

// Prevent canOpenURL checks for jailbreak apps
%hook UIApplication
- (BOOL)canOpenURL:(NSURL *)url {
	if (!url) return %orig;
	NSArray *blockedSchemes = @[@"cydia", @"sileo", @"zebra", @"filza", @"undecimus", @"activator"];
	NSString *scheme = [url scheme];
	if (!scheme) return %orig;
	for (NSString *blocked in blockedSchemes) {
		if ([scheme isEqualToString:blocked]) {
			return NO;
		}
	}
	return %orig;
}
%end

// ============================================
// FILE SYSTEM JAILBREAK DETECTION BYPASS
// ============================================

// Helper function to check if a path is a jailbreak-related path
// IMPORTANT: This function must be pure C (no ObjC) because it's called
// from C function hooks that may run before ObjC runtime initialization
static BOOL isBlockedPath(const char *path) {
	if (!path || path[0] == '\0') return NO;
	
	// Always allow access to app's own bundle
	if (strstr(path, "BeReal.app") != NULL) {
		return NO;
	}
	
	// Prefix checks using strncmp for efficiency
	static const char *blockedPrefixes[] = {
		"/var/jb",
		"/private/preboot/",
		"/private/var/jb",
		"/private/var/lib/apt",
		"/private/var/lib/cydia",
		"/private/var/stash",
		"/private/var/tmp/cydia",
		NULL
	};
	
	for (int i = 0; blockedPrefixes[i] != NULL; i++) {
		size_t len = strlen(blockedPrefixes[i]);
		if (strncmp(path, blockedPrefixes[i], len) == 0) {
			return YES;
		}
	}
	
	// Exact path checks
	static const char *blockedPaths[] = {
		"/Applications/Cydia.app",
		"/Applications/Sileo.app",
		"/Applications/Zebra.app",
		"/Applications/Filza.app",
		"/Applications/Installer.app",
		"/Applications/NewTerm.app",
		"/Applications/iFile.app",
		"/Library/MobileSubstrate/MobileSubstrate.dylib",
		"/Library/MobileSubstrate/DynamicLibraries",
		"/usr/lib/libhooker.dylib",
		"/usr/lib/libsubstitute.dylib",
		"/usr/lib/substitute",
		"/usr/lib/substrate",
		"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
		"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
		"/bin/bash",
		"/bin/sh",
		"/usr/sbin/sshd",
		"/usr/bin/sshd",
		"/usr/libexec/sftp-server",
		"/etc/apt",
		"/etc/ssh/sshd_config",
		"/private/etc/apt",
		"/private/etc/ssh/sshd_config",
		"/private/jailbreak.test",
		"/var/tmp/cydia.log",
		"/var/jb/Applications/Cydia.app",
		"/var/jb/Applications/Sileo.app",
		"/var/jb/Applications/Zebra.app",
		"/var/jb/usr/lib/libhooker.dylib",
		"/var/jb/usr/lib/libsubstitute.dylib",
		"/var/jb/bin/bash",
		"/var/jb/bin/sh",
		NULL
	};
	
	for (int i = 0; blockedPaths[i] != NULL; i++) {
		if (strcmp(path, blockedPaths[i]) == 0) {
			return YES;
		}
	}
	
	return NO;
}

// NOTE: C-level hooks (access, stat, lstat, fopen, getenv) removed
// as they can cause crashes in jailed/sideloaded environments.
// Using only ObjC hooks which are safer.

// NSFileManager hooks
%hook NSFileManager
- (BOOL)fileExistsAtPath:(NSString *)path {
	if (path && isBlockedPath([path UTF8String])) {
		return NO;
	}
	return %orig;
}

- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory {
	if (path && isBlockedPath([path UTF8String])) {
		return NO;
	}
	return %orig;
}

- (BOOL)isReadableFileAtPath:(NSString *)path {
	if (path && isBlockedPath([path UTF8String])) {
		return NO;
	}
	return %orig;
}

- (BOOL)isWritableFileAtPath:(NSString *)path {
	if (path && isBlockedPath([path UTF8String])) {
		return NO;
	}
	return %orig;
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error {
	if (path && isBlockedPath([path UTF8String])) {
		if (error) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil];
		return nil;
	}
	return %orig;
}

- (NSString *)destinationOfSymbolicLinkAtPath:(NSString *)path error:(NSError **)error {
	if (path && isBlockedPath([path UTF8String])) {
		if (error) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil];
		return nil;
	}
	return %orig;
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
	NSArray *contents = %orig;
	if (!contents) return contents;
	
	NSMutableArray *filtered = [NSMutableArray array];
	for (NSString *item in contents) {
		NSString *fullPath = [path stringByAppendingPathComponent:item];
		if (!isBlockedPath([fullPath UTF8String])) {
			[filtered addObject:item];
		}
	}
	return filtered;
}
%end

// ============================================
// SWIFT HOOKS GROUP
// ============================================
%group BeRealSwiftHooks

// BeReal's own JailbreakCheck class (new in 4.58.0)
%hook BeaJailbreakCheck
- (BOOL)isJailbroken {
	return NO;
}
+ (BOOL)isJailbroken {
	return NO;
}
- (BOOL)check {
	return NO;
}
+ (BOOL)check {
	return NO;
}
- (BOOL)isJailbreak {
	return NO;
}
+ (BOOL)isJailbreak {
	return NO;
}
%end

// CRITICAL: Capture authorization headers from BeReal API requests
// This is required for BeFake upload functionality
%hook NSMutableURLRequest
- (void)setAllHTTPHeaderFields:(NSDictionary *)arg1 {
	%orig;
	
	// Check if this is a BeReal API request with authorization
	if ([[arg1 allKeys] containsObject:@"Authorization"] && 
		[[arg1 allKeys] containsObject:@"bereal-device-id"]) {
		if ([arg1[@"Authorization"] length] > 0) {
			// Always update headers to ensure we have the latest token
			headers = [arg1 copy];
			[[BeaTokenManager sharedInstance] setHeaders:headers];
			NSLog(@"[MiniBea] Captured BeReal authorization headers (setAllHTTPHeaderFields)");
		}
	}
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
	%orig;
	
	// Also capture when setting Authorization header individually
	if ([field isEqualToString:@"Authorization"] && [value length] > 0) {
		NSMutableDictionary *existingHeaders = [[[BeaTokenManager sharedInstance] headers] mutableCopy] ?: [NSMutableDictionary dictionary];
		existingHeaders[@"Authorization"] = value;
		[[BeaTokenManager sharedInstance] setHeaders:existingHeaders];
		headers = existingHeaders;
		NSLog(@"[MiniBea] Captured BeReal Authorization header (setValue:forHTTPHeaderField:)");
	}
	
	// Capture device ID as well
	if ([field isEqualToString:@"bereal-device-id"] && [value length] > 0) {
		NSMutableDictionary *existingHeaders = [[[BeaTokenManager sharedInstance] headers] mutableCopy] ?: [NSMutableDictionary dictionary];
		existingHeaders[@"bereal-device-id"] = value;
		[[BeaTokenManager sharedInstance] setHeaders:existingHeaders];
		headers = existingHeaders;
		NSLog(@"[MiniBea] Captured BeReal device-id header");
	}
}
%end

// Remove blur effect from BeReals (allows viewing without posting)
%hook CAFilter
- (void)setValue:(id)arg1 forKey:(id)arg2 {
	// Remove the blur that gets applied to BeReals
	if ([self.name isEqualToString:@"gaussianBlur"] && [arg2 isEqualToString:@"inputRadius"]) {
		return;
	}
	%orig;
}
%end

// BeReal 4.58.0 - MainTabBarController for upload button
%hook MainTabBarController
- (void)viewDidLoad {
	%orig;
	
	// Add upload button after delay for view hierarchy setup
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self setupBeFakeUploadButton];
	});
}

- (void)viewDidAppear:(BOOL)animated {
	%orig;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self setupBeFakeUploadButton];
	});
}

%new
- (void)setupBeFakeUploadButton {
	// Check if already added
	if ([[self view] viewWithTag:31415]) return;
	
	// Find navigation bar in home view controller
	UINavigationController *homeNav = nil;
	for (UIViewController *vc in [self viewControllers]) {
		if ([vc isKindOfClass:[UINavigationController class]]) {
			UINavigationController *nav = (UINavigationController *)vc;
			NSString *className = NSStringFromClass([nav.viewControllers.firstObject class]);
			if ([className containsString:@"Home"] || [className containsString:@"Feed"] || [className containsString:@"POV"]) {
				homeNav = nav;
				break;
			}
		}
	}
	
	if (!homeNav) {
		// Use first navigation controller as fallback
		for (UIViewController *vc in [self viewControllers]) {
			if ([vc isKindOfClass:[UINavigationController class]]) {
				homeNav = (UINavigationController *)vc;
				break;
			}
		}
	}
	
	if (!homeNav) return;
	
	UINavigationBar *navBar = homeNav.navigationBar;
	if (!navBar) return;
	
	// Create upload button
	UIButton *uploadButton = [UIButton buttonWithType:UIButtonTypeCustom];
	uploadButton.tag = 31415;
	
	UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightMedium];
	UIImage *plusImage = [UIImage systemImageNamed:@"plus.app.fill" withConfiguration:config];
	[uploadButton setImage:plusImage forState:UIControlStateNormal];
	[uploadButton setTintColor:[UIColor whiteColor]];
	uploadButton.translatesAutoresizingMaskIntoConstraints = NO;
	[uploadButton addTarget:self action:@selector(handleBeFakeUploadTap) forControlEvents:UIControlEventTouchUpInside];
	
	// Find BeReal logo imageview in the navigation bar
	UIImageView *logoView = [self findLogoInView:navBar];
	
	if (logoView && logoView.superview) {
		// Add directly to logo's superview (usually a stack view)
		UIView *logoContainer = logoView.superview;
		[logoContainer addSubview:uploadButton];
		
		// Position right next to the logo
		[NSLayoutConstraint activateConstraints:@[
			[uploadButton.centerYAnchor constraintEqualToAnchor:logoView.centerYAnchor],
			[uploadButton.leadingAnchor constraintEqualToAnchor:logoView.trailingAnchor constant:10],
			[uploadButton.widthAnchor constraintEqualToConstant:30],
			[uploadButton.heightAnchor constraintEqualToConstant:30]
		]];
		NSLog(@"[MiniBea] Upload button added next to logo in container");
	} else {
		// Alternative: Add to navigation bar directly
		[navBar addSubview:uploadButton];
		
		// Center vertically in nav bar, position to the right of center
		[NSLayoutConstraint activateConstraints:@[
			[uploadButton.centerYAnchor constraintEqualToAnchor:navBar.centerYAnchor],
			[uploadButton.centerXAnchor constraintEqualToAnchor:navBar.centerXAnchor constant:60],
			[uploadButton.widthAnchor constraintEqualToConstant:30],
			[uploadButton.heightAnchor constraintEqualToConstant:30]
		]];
		NSLog(@"[MiniBea] Upload button added to navigation bar center area");
	}
}

%new
- (UIImageView *)findLogoInView:(UIView *)view {
	// Look for UIImageView that looks like the BeReal logo
	if ([view isKindOfClass:[UIImageView class]]) {
		UIImageView *imgView = (UIImageView *)view;
		CGSize size = imgView.frame.size;
		
		// BeReal logo is typically around 60-100pt wide and 25-40pt tall
		if (size.width > 50 && size.width < 150 && size.height > 15 && size.height < 50) {
			// Additional check: should be horizontally centered-ish
			CGFloat centerX = CGRectGetMidX(imgView.frame);
			CGFloat parentWidth = imgView.superview.frame.size.width;
			if (parentWidth > 0 && ABS(centerX - parentWidth/2) < parentWidth * 0.3) {
				return imgView;
			}
		}
	}
	
	for (UIView *subview in view.subviews) {
		UIImageView *found = [self findLogoInView:subview];
		if (found) return found;
	}
	return nil;
}

%new
- (void)handleBeFakeUploadTap {
	NSLog(@"[MiniBea] BeFake upload button tapped!");
	
	// Get the currently visible view controller
	UIViewController *topVC = self;
	while (topVC.presentedViewController) {
		topVC = topVC.presentedViewController;
	}
	
	// Create and present upload view controller
	BeaUploadViewController *uploadVC = [[BeaUploadViewController alloc] init];
	if (!uploadVC) {
		NSLog(@"[MiniBea] ERROR: Failed to create BeaUploadViewController!");
		return;
	}
	
	NSLog(@"[MiniBea] Presenting BeaUploadViewController from %@", NSStringFromClass([topVC class]));
	
	// Wrap in navigation controller for better presentation
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:uploadVC];
	navController.modalPresentationStyle = UIModalPresentationFullScreen;
	navController.navigationBarHidden = YES;
	
	[topVC presentViewController:navController animated:YES completion:^{
		NSLog(@"[MiniBea] BeaUploadViewController presented successfully!");
	}];
}
%end

// BeReal 4.58.0 - New DoubleMediaViewUIKitLegacyImpl from RealComponents framework
%hook DoubleMediaViewUIKitLegacyImpl

- (void)layoutSubviews {
	%orig;
	
	// Use global key for associated object
	BeaButton *existingButton = objc_getAssociatedObject(self, &kMinibeaDownloadButtonKey);
	
	// Add button once in layoutSubviews for reliability
	if (!existingButton) {
		NSLog(@"[MiniBea] DoubleMediaViewUIKitLegacyImpl layoutSubviews - adding download button");
		
		BeaButton *downloadButton = [BeaButton downloadButton];
		objc_setAssociatedObject(self, &kMinibeaDownloadButtonKey, downloadButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		[self addSubview:downloadButton];
		
		// Position at top-right corner
		[NSLayoutConstraint activateConstraints:@[
			[[downloadButton topAnchor] constraintEqualToAnchor:[self topAnchor] constant:12],
			[[downloadButton trailingAnchor] constraintEqualToAnchor:[self trailingAnchor] constant:-12],
			[[downloadButton widthAnchor] constraintEqualToConstant:36],
			[[downloadButton heightAnchor] constraintEqualToConstant:36]
		]];
		
		downloadButton.layer.zPosition = 99999;
		existingButton = downloadButton;
		NSLog(@"[MiniBea] Download button added to DoubleMediaViewUIKitLegacyImpl");
	}

	// Hide blur overlays
	for (UIView *subview in [self subviews]) {
		NSString *className = NSStringFromClass([subview class]);
		if ([className containsString:@"Blur"] ||
			[className containsString:@"VisualEffect"] ||
			[className containsString:@"Overlay"]) {
			[subview setHidden:YES];
			[subview setAlpha:0];
		}
	}

	// Ensure download button is at front
	if (existingButton) {
		[self bringSubviewToFront:existingButton];
	}
	
	[self setUserInteractionEnabled:YES];
}

- (BOOL)isUserInteractionEnabled {
	return YES;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	BeaButton *existingButton = objc_getAssociatedObject(self, &kMinibeaDownloadButtonKey);
	if (existingButton) {
		CGPoint buttonPoint = [existingButton convertPoint:point fromView:self];
		if ([existingButton pointInside:buttonPoint withEvent:event]) {
			return existingButton;
		}
	}
	return %orig;
}
%end

// BeReal 4.58.0 - UIImageView hook for all post images
// SDAnimatedImageView extends UIImageView, so this catches both
%hook UIImageView

- (void)layoutSubviews {
	%orig;
	
	// Use global associated object keys
	NSNumber *checked = objc_getAssociatedObject(self, &kMinibeaCheckedKey);
	BeaButton *existingButton = objc_getAssociatedObject(self, &kMinibeaDownloadButtonKey);
	
	// Skip if already processed
	if ([checked boolValue]) {
		if (existingButton) {
			[self bringSubviewToFront:existingButton];
		}
		return;
	}
	
	// Check size - post images are typically 150+ in at least one dimension
	CGSize size = self.frame.size;
	
	// Skip very small views (icons, avatars, etc.)
	if (size.width < 120 || size.height < 120) {
		return;
	}
	
	// Skip if no image loaded yet
	if (!self.image) return;
	
	// Mark as checked
	objc_setAssociatedObject(self, &kMinibeaCheckedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	// Check parent hierarchy for post-related views
	BOOL isPostImage = NO;
	UIView *checkView = [self superview];
	NSString *selfClass = NSStringFromClass([self class]);
	int depth = 0;
	
	// SDAnimatedImageView is a strong signal
	if ([selfClass containsString:@"SDAnimatedImageView"] ||
		[selfClass containsString:@"SDImage"]) {
		isPostImage = YES;
	}
	
	// Also check parent hierarchy
	while (checkView && depth < 20 && !isPostImage) {
		NSString *parentClass = NSStringFromClass([checkView class]);
		
		if ([parentClass containsString:@"POV"] ||
			[parentClass containsString:@"Post"] ||
			[parentClass containsString:@"Feed"] ||
			[parentClass containsString:@"DoubleMedia"] ||
			[parentClass containsString:@"MediaView"] ||
			[parentClass containsString:@"SwiftUI"] ||
			[parentClass containsString:@"Hosting"]) {
			isPostImage = YES;
			break;
		}
		
		// Check if inside a UICollectionView or UITableView
		if ([checkView isKindOfClass:[UICollectionViewCell class]] ||
			[checkView isKindOfClass:[UITableViewCell class]]) {
			isPostImage = YES;
			break;
		}
		
		checkView = [checkView superview];
		depth++;
	}
	
	if (!isPostImage) return;
	
	// Skip if already has our button
	if (existingButton) return;
	
	NSLog(@"[MiniBea] Adding download button to %@ (size: %.0fx%.0f)", selfClass, size.width, size.height);
	
	BeaButton *downloadButton = [BeaButton downloadButton];
	objc_setAssociatedObject(self, &kMinibeaDownloadButtonKey, downloadButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self setUserInteractionEnabled:YES];
	[self setClipsToBounds:NO]; // Ensure button isn't clipped
	[self addSubview:downloadButton];
	
	// Position in top-right corner inside the image
	[NSLayoutConstraint activateConstraints:@[
		[[downloadButton topAnchor] constraintEqualToAnchor:[self topAnchor] constant:10],
		[[downloadButton trailingAnchor] constraintEqualToAnchor:[self trailingAnchor] constant:-10],
		[[downloadButton widthAnchor] constraintEqualToConstant:32],
		[[downloadButton heightAnchor] constraintEqualToConstant:32]
	]];
	
	downloadButton.layer.zPosition = 9999;
	[self bringSubviewToFront:downloadButton];
}

- (void)setImage:(UIImage *)image {
	%orig;
	// Reset when image changes to allow button re-evaluation
	if (image) {
		objc_setAssociatedObject(self, &kMinibeaCheckedKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		[self setNeedsLayout];
	}
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	BeaButton *existingButton = objc_getAssociatedObject(self, &kMinibeaDownloadButtonKey);
	if (existingButton) {
		CGPoint buttonPoint = [existingButton convertPoint:point fromView:self];
		if ([existingButton pointInside:buttonPoint withEvent:event]) {
			return existingButton;
		}
	}
	return %orig;
}
%end

// BeReal 4.58.0 - BlurStateUseCaseImpl controls whether posts are blurred
%hook BlurStateUseCaseImpl
- (BOOL)isBlurred {
	return NO;
}
- (BOOL)isBlurredState {
	return NO;
}
- (id)blurState {
	return nil;
}
%end

// BeReal 4.58.0 - NewDoubleMediaViewModel blur handling
%hook NewDoubleMediaViewModel
- (BOOL)isBlurred {
	return NO;
}
- (BOOL)blurred {
	return NO;
}
%end

%hook AdvertNativeViewContainer
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

%end // end group BeRealSwiftHooks


// ============================================
// LEGACY HOOKS GROUP
// ============================================
%group LegacySwiftHooks

// Legacy SwiftUI MediaView for older BeReal versions
%hook MediaViewHosting
%property (nonatomic, strong) BeaButton *downloadButton;

- (void)drawRect:(CGRect)rect {
	%orig;

	// Legacy hook for older BeReal versions with SwiftUI-based media views
	if ([NSStringFromClass([[self subviews].lastObject class]) isEqualToString:@"_TtCOCV7SwiftUI11DisplayList11ViewUpdater8Platform13CGDrawingView"] && [[self subviews] count] > 5) { 
		for (int i = 1; i < [[self subviews] count]; i++) {
			[[self subviews][i] setHidden:YES];
		}
	}

	if ([[self subviews] count] > 0) {
		[self subviews][0].accessibilityIdentifier = @"Beaw";
	}

	if (![self downloadButton]) {
		BeaButton *downloadButton = [BeaButton downloadButton];
		downloadButton.layer.zPosition = 99;

		[self setDownloadButton:downloadButton];
		[self addSubview:downloadButton];

		[NSLayoutConstraint activateConstraints:@[
			[[[self downloadButton] trailingAnchor] constraintEqualToAnchor:[self trailingAnchor] constant:-11.6],
			[[[self downloadButton] bottomAnchor] constraintEqualToAnchor:[self topAnchor] constant:47.333]
		]];
	}
}
%end

// Legacy DoubleMediaView for older BeReal versions
%hook DoubleMediaViewLegacy
- (BOOL)isUserInteractionEnabled {
	if ([[self accessibilityIdentifier] isEqualToString:@"Beaw"]){
		return YES;
	}
	return %orig;
}
%end

%end // end group LegacySwiftHooks


%ctor {
	// Initialize Standard Hooks (C functions, ObjC classes that always exist)
    %init(_ungrouped);

	// Safe initialization for Swift hooks
	Class jailbreakCheckClass = NSClassFromString(@"_TtC6BeReal14JailbreakCheck");
	
	// MainTabBarController for upload button
	Class mainTabBarClass = NSClassFromString(@"_TtC6BeReal20MainTabBarController");
	if (!mainTabBarClass) mainTabBarClass = NSClassFromString(@"BeReal.MainTabBarController");
    
	Class doubleMediaClass = NSClassFromString(@"_TtC14RealComponents30DoubleMediaViewUIKitLegacyImpl");
	Class blurStateClass = NSClassFromString(@"_TtC18FeedsFeatureDomain20BlurStateUseCaseImpl");
	Class advertClass = NSClassFromString(@"_TtC11AdvertsData25AdvertNativeViewContainer");
	Class newDoubleMediaViewModelClass = NSClassFromString(@"_TtC14RealComponents23NewDoubleMediaViewModel");

    // Calculate fallbacks once
    Class safeJailbreakCheck = jailbreakCheckClass ?: [NSObject class];
    Class safeMainTabBar = mainTabBarClass ?: [NSObject class];
    Class safeDoubleMedia = doubleMediaClass ?: [NSObject class];
    Class safeBlurState = blurStateClass ?: [NSObject class];
    Class safeAdvert = advertClass ?: [NSObject class];
	Class safeNewDoubleMediaViewModel = newDoubleMediaViewModelClass ?: [NSObject class];
    
    if (jailbreakCheckClass || mainTabBarClass || doubleMediaClass || blurStateClass || advertClass || newDoubleMediaViewModelClass) {
        %init(BeRealSwiftHooks, 
            BeaJailbreakCheck = safeJailbreakCheck,
            MainTabBarController = safeMainTabBar,
            DoubleMediaViewUIKitLegacyImpl = safeDoubleMedia,
            BlurStateUseCaseImpl = safeBlurState,
            AdvertNativeViewContainer = safeAdvert,
			NewDoubleMediaViewModel = safeNewDoubleMediaViewModel
        );
    }

	// Legacy hooks - Only init if found (unlikely for 4.58.0, effectively disabled)
	Class mediaViewClass = NSClassFromString(@"_TtGC7SwiftUI14_UIHostingViewVS_14_ViewList_View_");
	Class doubleMediaLegacyClass = NSClassFromString(@"_TtC7SwiftUIP33_A34643117F00277B93DEBAB70EC0697116_UIInheritedView");

    Class safeMediaView = mediaViewClass ?: [NSObject class];
    Class safeDoubleMediaLegacy = doubleMediaLegacyClass ?: [NSObject class];

    if (mediaViewClass || doubleMediaLegacyClass) {
        %init(LegacySwiftHooks, 
            MediaViewHosting = safeMediaView, 
            DoubleMediaViewLegacy = safeDoubleMediaLegacy
        );
    }
}
