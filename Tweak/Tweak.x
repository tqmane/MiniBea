#import "Tweak.h"

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

// BeReal's own JailbreakCheck class (new in 4.58.0)
%hook JailbreakCheck
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
	NSArray *blockedSchemes = @[@"cydia", @"sileo", @"zebra", @"filza", @"undecimus", @"activator"];
	NSString *scheme = [url scheme];
	for (NSString *blocked in blockedSchemes) {
		if ([scheme isEqualToString:blocked]) {
			return NO;
		}
	}
	return %orig;
}
%end

// ============================================
// HOME VIEW CONTROLLER HOOKS - BeReal 4.58.0
// ============================================

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
	// Try to find the navigation bar or add button to the view hierarchy
	UIView *targetView = nil;
	
	// Search for the navigation bar logo or suitable container
	for (UIView *subview in [[self view] subviews]) {
		if ([subview isKindOfClass:[UIStackView class]] || 
			[NSStringFromClass([subview class]) containsString:@"NavBar"]) {
			targetView = subview;
			break;
		}
	}
	
	// Create upload button
	UIButton *uploadButton = [UIButton buttonWithType:UIButtonTypeSystem];
	UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:24];
	[uploadButton setImage:[UIImage systemImageNamed:@"plus.app" withConfiguration:config] forState:UIControlStateNormal];
	[uploadButton setTintColor:[UIColor whiteColor]];
	uploadButton.translatesAutoresizingMaskIntoConstraints = NO;
	[uploadButton addTarget:self action:@selector(handleUploadTap) forControlEvents:UIControlEventTouchUpInside];
	
	[[self view] addSubview:uploadButton];
	
	[NSLayoutConstraint activateConstraints:@[
		[[uploadButton topAnchor] constraintEqualToAnchor:[[self view] safeAreaLayoutGuide].topAnchor constant:8],
		[[uploadButton trailingAnchor] constraintEqualToAnchor:[[self view] trailingAnchor] constant:-16],
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

// Fallback: Legacy HomeViewController hook for older versions
%hook HomeViewController
- (void)viewDidLoad {
	%orig;

	UIStackView *stackView = (UIStackView *)[[self ibNavBarLogoImageView] superview];
	if (stackView) {
		stackView.axis = UILayoutConstraintAxisHorizontal;
		stackView.alignment = UIStackViewAlignmentCenter;
		
		UIImageView *plusImage = [[UIImageView alloc] init];
		plusImage.image = [UIImage systemImageNamed:@"plus.app"];
		plusImage.translatesAutoresizingMaskIntoConstraints = NO;

		[stackView addArrangedSubview:plusImage];

		UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
		[stackView addGestureRecognizer:tapGestureRecognizer];
		[stackView setUserInteractionEnabled:YES];
	}
}

%new
- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer {
	if (![[BeaTokenManager sharedInstance] BRAccessToken]) return;

	BeaUploadViewController *beaUploadViewController = [[BeaUploadViewController alloc] init];
	beaUploadViewController.modalPresentationStyle = UIModalPresentationFullScreen;
	[self presentViewController:beaUploadViewController animated:YES completion:nil];
}
%end

%hook NSMutableURLRequest
-(void)setAllHTTPHeaderFields:(NSDictionary *)arg1 {
	%orig;

	if ([[arg1 allKeys] containsObject:@"Authorization"] && [[arg1 allKeys] containsObject:@"bereal-device-id"] && !headers) {
		if ([arg1[@"Authorization"] length] > 0) {
			headers = (NSDictionary *)arg1;
			[[BeaTokenManager sharedInstance] setHeaders:headers];
		}
	} 
}
%end

%hook CAFilter
-(void)setValue:(id)arg1 forKey:(id)arg2 {
    // remove the blur that gets applied to the BeReals
	// this is kind of a fallback if the normal unblur function somehow fails (BeReal 2.0+)

	if (([arg1 isEqual:@(13)] || [arg1 isEqual:@(8)]) && [self.name isEqual:@"gaussianBlur"]) {
		return %orig(0, arg2);
	}
    %orig;
}
%end

%hook MediaView
%property (nonatomic, strong) BeaButton *downloadButton;

- (void)drawRect:(CGRect)rect {
	%orig;

	// Legacy hook for older BeReal versions with SwiftUI-based media views
	// Check if we need to remove subviews other than the main image (to keep the reaction&comment button)
	// 1. Not posted yet & 2. Not tagged in that post (especially to keep the reshare button)
	if ([NSStringFromClass([[self subviews].lastObject class]) isEqualToString:@"_TtCOCV7SwiftUI11DisplayList11ViewUpdater8Platform13CGDrawingView"] && [[self subviews] count] > 5) { 
		for (int i = 1; i < [[self subviews] count]; i++) {
			[[self subviews][i] setHidden:YES];
		}
	}

	// Every time we swich images it resets the user interaction stat, so we set the identifier and track it in the hook
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

// BeReal 4.58.0 - New DoubleMediaViewUIKitLegacyImpl from RealComponents framework
%hook DoubleMediaViewUIKitLegacyImpl
%property (nonatomic, strong) BeaButton *downloadButton;

- (void)layoutSubviews {
	%orig;

	// Add download button if not already added
	if (![self downloadButton]) {
		BeaButton *downloadButton = [BeaButton downloadButton];
		downloadButton.layer.zPosition = 999;
		[self setDownloadButton:downloadButton];
		[self addSubview:downloadButton];

		[NSLayoutConstraint activateConstraints:@[
			[[downloadButton trailingAnchor] constraintEqualToAnchor:[self trailingAnchor] constant:-11.6],
			[[downloadButton topAnchor] constraintEqualToAnchor:[self topAnchor] constant:11.6]
		]];
	}
	
	// Ensure user interaction is enabled for image switching
	[self setUserInteractionEnabled:YES];
}

- (void)didMoveToSuperview {
	%orig;
	
	// Alternative place to add download button
	if ([self superview] && ![self downloadButton]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (![self downloadButton]) {
				BeaButton *downloadButton = [BeaButton downloadButton];
				downloadButton.layer.zPosition = 999;
				[self setDownloadButton:downloadButton];
				[self addSubview:downloadButton];

				[NSLayoutConstraint activateConstraints:@[
					[[downloadButton trailingAnchor] constraintEqualToAnchor:[self trailingAnchor] constant:-11.6],
					[[downloadButton topAnchor] constraintEqualToAnchor:[self topAnchor] constant:11.6]
				]];
			}
		});
	}
}

- (BOOL)isUserInteractionEnabled {
	return YES;
}
%end

%hook DoubleMediaView
- (BOOL)isUserInteractionEnabled {
	// This prevent us from using the reaction&comment button if we always return yes (although it allows us to switch images when not posted yet)
	// so only apply it to the desired element
	if ([[self accessibilityIdentifier] isEqualToString:@"Beaw"]){
		return YES;
	}
	return %orig;
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

// ============================================
// FILE SYSTEM JAILBREAK DETECTION BYPASS
// ============================================

BOOL isBlockedPath(const char *path) {
    if (!path) return NO;
    
    NSString *pathStr = @(path);
    
    // Rootless jailbreak paths (Dopamine, palera1n, etc.)
    if ([pathStr hasPrefix:@"/var/jb/"] || 
        [pathStr hasPrefix:@"/var/jb"] ||
        [pathStr hasPrefix:@"/private/preboot/"] || 
        [pathStr hasPrefix:@"/private/var/jb"] ||
        [pathStr hasPrefix:@"/private/var/lib/apt"] ||
        [pathStr hasPrefix:@"/private/var/lib/cydia"] ||
        [pathStr hasPrefix:@"/private/var/stash"] ||
        [pathStr hasPrefix:@"/private/var/tmp/cydia"] ||
        [pathStr hasPrefix:@"/var/LIB/"] ||
        [pathStr hasPrefix:@"/var/cache/apt"] ||
        [pathStr hasPrefix:@"/var/lib/dpkg"] ||
        [pathStr hasPrefix:@"/usr/lib/TweakInject"] ||
        [pathStr hasPrefix:@"/Library/TweakInject"] ||
        [pathStr hasPrefix:@"/Library/MobileSubstrate"]) {
        return YES;
    }
    
    NSArray *jbPaths = @[
        // Classic jailbreak paths
        @"/Applications/Cydia.app",
        @"/Applications/Sileo.app",
        @"/Applications/Zebra.app",
        @"/Applications/Filza.app",
        @"/Applications/Installer.app",
        @"/Applications/NewTerm.app",
        @"/Applications/blackra1n.app",
        @"/Applications/FakeCarrier.app",
        @"/Applications/Icy.app",
        @"/Applications/IntelliScreen.app",
        @"/Applications/MxTube.app",
        @"/Applications/RockApp.app",
        @"/Applications/SBSettings.app",
        @"/Applications/WinterBoard.app",
        // Substrate/Substitute
        @"/Library/MobileSubstrate/MobileSubstrate.dylib",
        @"/Library/MobileSubstrate/DynamicLibraries",
        @"/usr/lib/libhooker.dylib",
        @"/usr/lib/libsubstitute.dylib",
        @"/usr/lib/substrate",
        @"/usr/lib/TweakInject",
        // System daemons
        @"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
        @"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
        // Unix binaries
        @"/bin/bash",
        @"/bin/sh",
        @"/usr/sbin/sshd",
        @"/usr/bin/sshd",
        @"/usr/libexec/sftp-server",
        @"/usr/bin/ssh",
        @"/etc/ssh/sshd_config",
        @"/etc/apt",
        @"/etc/apt/sources.list.d",
        @"/etc/apt/sources.list.d/sileo.sources",
        @"/etc/apt/sources.list.d/cydia.list",
        // Package managers
        @"/private/var/lib/apt",
        @"/private/var/lib/apt/",
        @"/private/var/lib/cydia",
        @"/var/lib/dpkg/info",
        @"/var/cache/apt",
        // Test files
        @"/private/jailbreak.test",
        @"/var/mobile/Library/Preferences/ABPattern",
        @"/var/tmp/cydia.log",
        // Rootless paths
        @"/var/jb",
        @"/var/jb/usr/lib",
        @"/var/jb/Library/LaunchDaemons",
        // Common tweaks
        @"/Library/PreferenceBundles",
        @"/Library/PreferenceLoader",
        @"/Library/Themes",
        // Binaries
        @"/usr/bin/cycript",
        @"/usr/local/bin/cycript",
        @"/usr/lib/libcycript.dylib"
    ];

    for (NSString *jbPath in jbPaths) {
        if ([pathStr isEqualToString:jbPath] || [pathStr hasPrefix:[jbPath stringByAppendingString:@"/"]]) {
            return YES;
        }
    }
    
    // Check for common jailbreak-related substrings
    NSArray *jbSubstrings = @[@"cydia", @"substrate", @"substitute", @"sileo", @"zebra", @"libhooker", @"TweakInject", @"jailbreak"];
    for (NSString *substr in jbSubstrings) {
        if ([pathStr.lowercaseString containsString:substr]) {
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

- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory {
    if (isBlockedPath([path UTF8String])) {
        return NO;
    }
    return %orig;
}

- (BOOL)isReadableFileAtPath:(NSString *)path {
    if (isBlockedPath([path UTF8String])) {
        return NO;
    }
    return %orig;
}

- (BOOL)isWritableFileAtPath:(NSString *)path {
    if (isBlockedPath([path UTF8String])) {
        return NO;
    }
    return %orig;
}

- (BOOL)isExecutableFileAtPath:(NSString *)path {
    if (isBlockedPath([path UTF8String])) {
        return NO;
    }
    return %orig;
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
    if (isBlockedPath([path UTF8String])) {
        if (error) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil];
        return nil;
    }
    return %orig;
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error {
    if (isBlockedPath([path UTF8String])) {
        if (error) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil];
        return nil;
    }
    return %orig;
}
%end

// ============================================
// ADVERTISEMENT REMOVAL
// ============================================

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

%ctor {
	// Get classes with fallbacks for different BeReal versions
	Class homeViewHostingClass = objc_getClass("BeReal.HomeViewHostingController");
	if (!homeViewHostingClass) {
		homeViewHostingClass = objc_getClass("_TtC6BeReal25HomeViewHostingController");
	}
	
	// Jailbreak detection class (new in 4.58.0)
	Class jailbreakCheckClass = objc_getClass("_TtC6BeReal14JailbreakCheck");
	if (!jailbreakCheckClass) {
		jailbreakCheckClass = objc_getClass("BeReal.JailbreakCheck");
	}
	
	Class doubleMediaClass = objc_getClass("_TtC14RealComponents30DoubleMediaViewUIKitLegacyImpl");
	Class mediaViewClass = objc_getClass("_TtGC7SwiftUI14_UIHostingViewVS_14_ViewList_View_");
	Class doubleMediaViewClass = objc_getClass("_TtC7SwiftUIP33_A34643117F00277B93DEBAB70EC0697116_UIInheritedView");
	Class homeViewControllerClass = objc_getClass("BeReal.HomeViewController");
	Class advertsContainerClass = objc_getClass("_TtC11AdvertsData25AdvertNativeViewContainer");
	
	%init(
	  // BeReal 4.58.0 - Jailbreak detection bypass
	  JailbreakCheck = jailbreakCheckClass,
	  // BeReal 4.58.0 - New UIKit-based DoubleMediaView from RealComponents
	  DoubleMediaViewUIKitLegacyImpl = doubleMediaClass,
	  // BeReal 4.58.0 - HomeViewHostingController
	  HomeViewHostingController = homeViewHostingClass,
	  // Legacy SwiftUI MediaView (for older versions < 4.58.0)
	  MediaView = mediaViewClass,
	  DoubleMediaView = doubleMediaViewClass,
	  // Legacy HomeViewController (for older versions)
      HomeViewController = homeViewControllerClass,
	  // Ads container - Updated class name for 4.58.0
	  AdvertsDataNativeViewContainer = advertsContainerClass
	);
}