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

// Legacy SwiftUI MediaView for older BeReal versions
%hook MediaViewHosting
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
			[[downloadButton trailingAnchor] constraintEqualToAnchor:[self trailingAnchor] constant:-12],
			[[downloadButton bottomAnchor] constraintEqualToAnchor:[self bottomAnchor] constant:-12],
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

// Legacy DoubleMediaView for older BeReal versions
%hook _TtC7SwiftUIP33_A34643117F00277B93DEBAB70EC0697116_UIInheritedView
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

// Helper to check if current call is from BeReal bundle
static BOOL isCalledFromBeReal(void) {
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    return [bundleId isEqualToString:@"AlexisBarreyat.BeReal"];
}

BOOL isBlockedPath(const char *path) {
    if (!path) return NO;
    
    // Only block paths when called from BeReal
    if (!isCalledFromBeReal()) return NO;
    
    NSString *pathStr = @(path);
    
    // Don't block paths that the tweak itself might need
    if ([pathStr containsString:@"Bea.bundle"] || 
        [pathStr containsString:@"MiniBea"]) {
        return NO;
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
        // System daemons
        @"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
        @"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
        // Unix binaries that indicate jailbreak
        @"/bin/bash",
        @"/usr/sbin/sshd",
        @"/usr/bin/sshd",
        @"/etc/apt",
        // Test files
        @"/private/jailbreak.test",
        @"/var/tmp/cydia.log"
    ];

    for (NSString *jbPath in jbPaths) {
        if ([pathStr isEqualToString:jbPath]) {
            return YES;
        }
    }
    
    // Check for common jailbreak-related substrings (but not ones that affect tweaks)
    NSArray *jbSubstrings = @[@"cydia", @"sileo", @"zebra", @"jailbreak"];
    for (NSString *substr in jbSubstrings) {
        if ([pathStr.lowercaseString containsString:substr]) {
            return YES;
        }
    }
    
    return NO;
}

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

- (BOOL)isExecutableFileAtPath:(NSString *)path {
    if (path && isBlockedPath([path UTF8String])) {
        return NO;
    }
    return %orig;
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
    if (path && isBlockedPath([path UTF8String])) {
        if (error) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil];
        return nil;
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
%end

// ============================================
// BLUR STATE BYPASS - Remove "Post to View" overlay
// ============================================

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

// ============================================
// ADVERTISEMENT REMOVAL
// ============================================

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

%ctor {
	// Dynamically assign Swift mangled class names to short hook names
	%init(
		BeaJailbreakCheck = objc_getClass("_TtC6BeReal14JailbreakCheck"),
		HomeViewHostingController = objc_getClass("_TtC6BeReal25HomeViewHostingController"),
		MediaViewHosting = objc_getClass("_TtGC7SwiftUI14_UIHostingViewVS_14_ViewList_View_"),
		DoubleMediaViewUIKitLegacyImpl = objc_getClass("_TtC14RealComponents30DoubleMediaViewUIKitLegacyImpl"),
		BlurStateUseCaseImpl = objc_getClass("_TtC18FeedsFeatureDomain20BlurStateUseCaseImpl"),
		AdvertNativeViewContainer = objc_getClass("_TtC11AdvertsData25AdvertNativeViewContainer")
	);
}
