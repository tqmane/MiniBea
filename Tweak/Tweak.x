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
BOOL isBlockedPath(const char *path) {
	if (!path) return NO;

	NSString *pathStr = @(path);
	if (!pathStr || pathStr.length == 0) return NO;

	// Always allow access to app's own bundle
	if ([pathStr containsString:@"BeReal.app"]) {
		return NO;
	}

	// Prefix checks (Rootless & Legacy)
	if ([pathStr hasPrefix:@"/var/jb"] ||
		[pathStr hasPrefix:@"/private/preboot/"] ||
		[pathStr hasPrefix:@"/private/var/jb"] ||
		[pathStr hasPrefix:@"/private/var/lib/apt"] ||
		[pathStr hasPrefix:@"/private/var/lib/cydia"] ||
		[pathStr hasPrefix:@"/private/var/stash"] ||
		[pathStr hasPrefix:@"/private/var/tmp/cydia"]) {
		return YES;
	}

	// Exact path checks
	NSArray *jbPaths = @[
		// Classic jailbreak paths (rootful)
		@"/Applications/Cydia.app",
		@"/Applications/Sileo.app",
		@"/Applications/Zebra.app",
		@"/Applications/Filza.app",
		@"/Applications/Installer.app",
		@"/Applications/NewTerm.app",
		@"/Applications/iFile.app",
		// Substrate/Substitute (rootful)
		@"/Library/MobileSubstrate/MobileSubstrate.dylib",
		@"/Library/MobileSubstrate/DynamicLibraries",
		@"/usr/lib/libhooker.dylib",
		@"/usr/lib/libsubstitute.dylib",
		@"/usr/lib/substitute",
		@"/usr/lib/substrate",
		// System daemons
		@"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
		@"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
		// Unix binaries that indicate jailbreak (rootful)
		@"/bin/bash",
		@"/bin/sh",
		@"/usr/sbin/sshd",
		@"/usr/bin/sshd",
		@"/usr/libexec/sftp-server",
		@"/etc/apt",
		@"/etc/ssh/sshd_config",
		@"/private/etc/apt",
		@"/private/etc/ssh/sshd_config",
		// Test files
		@"/private/jailbreak.test",
		@"/var/tmp/cydia.log",
		// Additional rootless paths (explicit check just in case)
		@"/var/jb/Applications/Cydia.app",
		@"/var/jb/Applications/Sileo.app",
		@"/var/jb/Applications/Zebra.app",
		@"/var/jb/usr/lib/libhooker.dylib",
		@"/var/jb/usr/lib/libsubstitute.dylib",
		@"/var/jb/bin/bash",
		@"/var/jb/bin/sh"
	];

	for (NSString *jbPath in jbPaths) {
		if ([pathStr isEqualToString:jbPath]) {
			return YES;
		}
	}

	return NO;
}

// C-Level Hooks for system calls
%hookf(int, access, const char *path, int amode) {
	if (isBlockedPath(path)) {
		errno = ENOENT;
		return -1;
	}
	return %orig;
}

%hookf(int, stat, const char *path, struct stat *buf) {
	if (isBlockedPath(path)) {
		errno = ENOENT;
		return -1;
	}
	return %orig;
}

%hookf(int, lstat, const char *path, struct stat *buf) {
	if (isBlockedPath(path)) {
		errno = ENOENT;
		return -1;
	}
	return %orig;
}

%hookf(FILE *, fopen, const char *path, const char *mode) {
	if (isBlockedPath(path)) {
		errno = ENOENT;
		return NULL;
	}
	return %orig;
}

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

// Updated for BeReal 4.58.0 - HomeViewHostingController replaces HomeViewController
%hook HomeViewHostingController
- (void)viewDidLoad {
	%orig;
	
	// Find the navigation bar and add a plus button for uploads
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self setupUploadButton];
	});
}

%new
- (void)setupUploadButton {
	// Create upload button
	UIButton *uploadButton = [UIButton buttonWithType:UIButtonTypeSystem];
	UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:24];
	[uploadButton setImage:[UIImage systemImageNamed:@"plus.app" withConfiguration:config] forState:UIControlStateNormal];
	[uploadButton setTintColor:[UIColor whiteColor]];
	uploadButton.layer.zPosition = 9999;
	uploadButton.translatesAutoresizingMaskIntoConstraints = NO;
	[uploadButton addTarget:self action:@selector(handleUploadTap) forControlEvents:UIControlEventTouchUpInside];
	
	[[self view] addSubview:uploadButton];
	
	[NSLayoutConstraint activateConstraints:@[
		[[uploadButton topAnchor] constraintEqualToAnchor:[[self view] safeAreaLayoutGuide].topAnchor constant:10],
		[[uploadButton leadingAnchor] constraintEqualToAnchor:[[self view] leadingAnchor] constant:16],
		[[uploadButton widthAnchor] constraintEqualToConstant:44],
		[[uploadButton heightAnchor] constraintEqualToConstant:44]
	]];
}

%new
- (void)handleUploadTap {
	if (![[BeaTokenManager sharedInstance] BRAccessToken]) return;

	BeaUploadViewController *beaUploadViewController = [[BeaUploadViewController alloc] init];
	beaUploadViewController.modalPresentationStyle = UIModalPresentationFullScreen;
	[self presentViewController:beaUploadViewController animated:YES completion:nil];
}
%end

// BeReal 4.58.0 - New DoubleMediaViewUIKitLegacyImpl from RealComponents framework
%hook DoubleMediaViewUIKitLegacyImpl
%property (nonatomic, strong) BeaButton *downloadButton;

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
		// Also check nested subviews
		for (UIView *nested in [subview subviews]) {
			if ([NSStringFromClass([nested class]) containsString:@"Label"] ||
				[NSStringFromClass([nested class]) containsString:@"Text"]) {
				[nested setHidden:YES];
			}
		}
	}

	// Add download button if not already added
	if (![self downloadButton]) {
		BeaButton *downloadButton = [BeaButton downloadButton];
		downloadButton.layer.zPosition = 999;
		[self setDownloadButton:downloadButton];
		[self addSubview:downloadButton];

		[NSLayoutConstraint activateConstraints:@[
			[[downloadButton trailingAnchor] constraintEqualToAnchor:[self trailingAnchor] constant:-11.6],
			[[downloadButton bottomAnchor] constraintEqualToAnchor:[self topAnchor] constant:47.333],
			[[downloadButton widthAnchor] constraintEqualToConstant:32],
			[[downloadButton heightAnchor] constraintEqualToConstant:32]
		]];
	}
	
	// Ensure user interaction is enabled for image switching
	[self setUserInteractionEnabled:YES];
}

- (void)didMoveToSuperview {
	%orig;
	
	// Trigger layout to add download button
	if ([self superview]) {
		[self setNeedsLayout];
	}
}

- (BOOL)isUserInteractionEnabled {
	return YES;
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
	Class homeViewClass = NSClassFromString(@"_TtC6BeReal25HomeViewHostingController");
    if (!homeViewClass) homeViewClass = NSClassFromString(@"BeReal.HomeViewHostingController"); // Fallback
    
	Class doubleMediaClass = NSClassFromString(@"_TtC14RealComponents30DoubleMediaViewUIKitLegacyImpl");
	Class blurStateClass = NSClassFromString(@"_TtC18FeedsFeatureDomain20BlurStateUseCaseImpl");
	Class advertClass = NSClassFromString(@"_TtC11AdvertsData25AdvertNativeViewContainer");
	Class newDoubleMediaViewModelClass = NSClassFromString(@"_TtC14RealComponents23NewDoubleMediaViewModel");
	
    // Init group only if critical classes are found, or init individual hooks if they exist
    // Note: %init(Group, Class=Target) initializes the *Group*. 
    // If a class is nil in the mapping, it usually warns or defaults. 
    // We will only init if we found the class to avoid hooking NSObject.

    // Calculate fallbacks once
    Class safeJailbreakCheck = jailbreakCheckClass ?: [NSObject class];
    Class safeHomeView = homeViewClass ?: [NSObject class];
    Class safeDoubleMedia = doubleMediaClass ?: [NSObject class];
    Class safeBlurState = blurStateClass ?: [NSObject class];
    Class safeAdvert = advertClass ?: [NSObject class];
	Class safeNewDoubleMediaViewModel = newDoubleMediaViewModelClass ?: [NSObject class];

    // Initialize the whole group once with safe classes (hooking NSObject for missing ones is harmless with our conditional implementation checking for nil or specific methods, 
    // BUT hooking NSObject methods like checking for jailbreak might be risky if we aren't careful.
    // However, our hooks are specific: "isJailbroken", "check", "setupUploadButton" (new method), "layoutSubviews".
    // Hooking likely-unique methods on NSObject is safe. "isJailbroken" on NSObject is fine if it returns NO.
    // "layoutSubviews" on NSObject doesn't exist (it's UIView), so that's fine.
    
    // Actually, to be safer, we can just use the mapping. Logos allows hooking NSObject if the selector matches.
    
    if (jailbreakCheckClass || homeViewClass || doubleMediaClass || blurStateClass || advertClass || newDoubleMediaViewModelClass) {
        %init(BeRealSwiftHooks, 
            BeaJailbreakCheck = safeJailbreakCheck,
            HomeViewHostingController = safeHomeView,
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
