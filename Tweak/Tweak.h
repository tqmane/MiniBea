#import <UIKit/UIKit.h>
#import "fishhook/fishhook.h"
#import "Utilities/Button/BeaButton.h"
#import "BeFake/TokenManager/BeaTokenManager.h"
#import "BeFake/ViewControllers/UploadViewController/BeaUploadViewController.h"

NSDictionary *headers;

@interface AdvertsDataNativeViewContainer : UIView
@end

@interface DoubleMediaViewUIKitLegacyImpl : UIView
@property (nonatomic, strong) BeaButton *downloadButton;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

@interface PAGDeviceHelper : NSObject
+ (BOOL)bu_isJailBroken;
@end

@interface STKDevice : NSObject
+ (BOOL)containsJailbrokenFiles;
+ (BOOL)containsJailbrokenPermissions;
+ (BOOL)isJailbroken;
@end

@interface CAFilter : NSObject
@property (copy) NSString *name;
@end
