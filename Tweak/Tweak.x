#import "Tweak.h"
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

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

// BeReal 4.58.0 - MainTabBarController for upload button
%hook MainTabBarController
- (void)viewDidLoad {
	%orig;
	
	// Add upload button after a delay to ensure view hierarchy is ready
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self setupBeFakeUploadButton];
	});
}

- (void)viewDidAppear:(BOOL)animated {
	%orig;
	
	// Re-check button setup
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self setupBeFakeUploadButton];
	});
}

%new
- (void)setupBeFakeUploadButton {
	// Check if already added using tag
	if ([[self view] viewWithTag:31415]) return;
	
	// Find Home navigation controller
	UINavigationController *homeNav = nil;
	for (UIViewController *vc in [self viewControllers]) {
		if ([vc isKindOfClass:[UINavigationController class]]) {
			UINavigationController *nav = (UINavigationController *)vc;
			NSString *className = NSStringFromClass([nav.viewControllers.firstObject class]);
			if ([className containsString:@"Home"] || [className containsString:@"Feed"]) {
				homeNav = nav;
				break;
			}
		}
	}
	
	if (!homeNav) {
		// Fallback: use first navigation controller
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
	UIButton *uploadButton = [UIButton buttonWithType:UIButtonTypeSystem];
	uploadButton.tag = 31415;
	
	UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightMedium];
	[uploadButton setImage:[UIImage systemImageNamed:@"plus.app.fill" withConfiguration:config] forState:UIControlStateNormal];
	[uploadButton setTintColor:[UIColor whiteColor]];
	uploadButton.translatesAutoresizingMaskIntoConstraints = NO;
	[uploadButton addTarget:self action:@selector(handleBeFakeUploadTap) forControlEvents:UIControlEventTouchUpInside];
	
	// Find logo in navigation bar
	UIImageView *logoView = [self findLogoInView:navBar];
	
	if (logoView && logoView.superview) {
		UIView *container = logoView.superview;
		[container addSubview:uploadButton];
		
		[NSLayoutConstraint activateConstraints:@[
			[[uploadButton centerYAnchor] constraintEqualToAnchor:[logoView centerYAnchor]],
			[[uploadButton leadingAnchor] constraintEqualToAnchor:[logoView trailingAnchor] constant:8],
			[[uploadButton widthAnchor] constraintEqualToConstant:28],
			[[uploadButton heightAnchor] constraintEqualToConstant:28]
		]];
	} else {
		// Fallback: Add to top of main view
		UIView *mainView = [self view];
		[mainView addSubview:uploadButton];
		
		[NSLayoutConstraint activateConstraints:@[
			[[uploadButton topAnchor] constraintEqualToAnchor:[mainView safeAreaLayoutGuide].topAnchor constant:5],
			[[uploadButton centerXAnchor] constraintEqualToAnchor:[mainView centerXAnchor] constant:55],
			[[uploadButton widthAnchor] constraintEqualToConstant:28],
			[[uploadButton heightAnchor] constraintEqualToConstant:28]
		]];
	}
}

%new
- (UIImageView *)findLogoInView:(UIView *)view {
	if ([view isKindOfClass:[UIImageView class]]) {
		CGSize size = view.frame.size;
		// BeReal logo is typically 60-100pt wide
		if (size.width > 50 && size.width < 120 && size.height > 20 && size.height < 45) {
			return (UIImageView *)view;
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
%property (nonatomic, strong) BeaButton *downloadButton;

- (void)didMoveToSuperview {
	%orig;
	NSLog(@"[MiniBea] DoubleMediaViewUIKitLegacyImpl didMoveToSuperview - superview: %@", [self superview]);
	
	// Only add button when added to superview and button doesn't exist
	if ([self superview] && ![self downloadButton]) {
		NSLog(@"[MiniBea] Adding download button to DoubleMediaViewUIKitLegacyImpl");
		BeaButton *downloadButton = [BeaButton downloadButton];
		[self setDownloadButton:downloadButton];
		[self addSubview:downloadButton];
		
		// Position at top-right corner INSIDE the post image
		[NSLayoutConstraint activateConstraints:@[
			[[downloadButton topAnchor] constraintEqualToAnchor:[self topAnchor] constant:8],
			[[downloadButton trailingAnchor] constraintEqualToAnchor:[self trailingAnchor] constant:-8],
			[[downloadButton widthAnchor] constraintEqualToConstant:28],
			[[downloadButton heightAnchor] constraintEqualToConstant:28]
		]];
		NSLog(@"[MiniBea] Download button added successfully to DoubleMediaViewUIKitLegacyImpl");
	}
}

- (void)layoutSubviews {
	%orig;

	// Hide "Post to View" overlay views - find and hide blur overlays
	for (UIView *subview in [self subviews]) {
		// Hide blur effect views and overlay text
		if ([NSStringFromClass([subview class]) containsString:@"Blur"] ||
			[NSStringFromClass([subview class]) containsString:@"VisualEffect"] ||
			[NSStringFromClass([subview class]) containsString:@"Overlay"]) {
			[subview setHidden:YES];
			[subview setAlpha:0];
		}
	}

	// Ensure download button is always at the front
	if ([self downloadButton]) {
		[self downloadButton].layer.zPosition = 9999;
		[self bringSubviewToFront:[self downloadButton]];
	}
	
	// Ensure user interaction is enabled
	[self setUserInteractionEnabled:YES];
}

- (BOOL)isUserInteractionEnabled {
	return YES;
}

// Ensure this view can respond to touches on download button
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	// First check if the download button should receive the touch
	if ([self downloadButton]) {
		CGPoint buttonPoint = [[self downloadButton] convertPoint:point fromView:self];
		if ([[self downloadButton] pointInside:buttonPoint withEvent:event]) {
			return [self downloadButton];
		}
	}
	return %orig;
}
%end

// BeReal 4.58.0 - Hook _UIHostingView to add download button to SwiftUI post views
%hook _UIHostingView
%property (nonatomic, strong) BeaButton *downloadButton;

- (void)layoutSubviews {
	%orig;
	
	// Check if this is a post-related hosting view
	NSString *className = NSStringFromClass([self class]);
	
	// Skip if already has button
	if ([self downloadButton]) {
		[self bringSubviewToFront:[self downloadButton]];
		return;
	}
	
	// Check parent hierarchy for post-related views
	BOOL isPostView = NO;
	UIView *checkView = [self superview];
	for (int i = 0; i < 8 && checkView; i++) {
		NSString *parentClass = NSStringFromClass([checkView class]);
		// Look for POV (Point of View) post containers or Double media views
		if ([parentClass containsString:@"POV"] ||
			[parentClass containsString:@"DoubleMedia"] ||
			[parentClass containsString:@"PostCell"] ||
			[parentClass containsString:@"FeedPost"]) {
			isPostView = YES;
			break;
		}
		checkView = [checkView superview];
	}
	
	if (!isPostView) return;
	
	// Check size - post images are typically large
	CGSize size = self.frame.size;
	if (size.width < 200 || size.height < 200) return;
	
	NSLog(@"[MiniBea] Found post hosting view: %@ (size: %.0fx%.0f)", className, size.width, size.height);
	
	BeaButton *downloadButton = [BeaButton downloadButton];
	[self setDownloadButton:downloadButton];
	[self setUserInteractionEnabled:YES];
	[self addSubview:downloadButton];
	
	[NSLayoutConstraint activateConstraints:@[
		[[downloadButton topAnchor] constraintEqualToAnchor:[self topAnchor] constant:12],
		[[downloadButton trailingAnchor] constraintEqualToAnchor:[self trailingAnchor] constant:-12],
		[[downloadButton widthAnchor] constraintEqualToConstant:32],
		[[downloadButton heightAnchor] constraintEqualToConstant:32]
	]];
	
	downloadButton.layer.zPosition = 9999;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	if ([self downloadButton]) {
		CGPoint buttonPoint = [[self downloadButton] convertPoint:point fromView:self];
		if ([[self downloadButton] pointInside:buttonPoint withEvent:event]) {
			return [self downloadButton];
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
