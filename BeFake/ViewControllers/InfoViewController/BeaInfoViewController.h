#import <UIKit/UIKit.h>

@interface BeaInfoViewController : UIViewController
@property (nonatomic, strong) UIImageView *profileImageView;
@property (nonatomic, strong) UILabel *twitterLabel;
@property (nonatomic, strong) UILabel *smallLabel;
@property (nonatomic, strong) UIView *wrapperView;
@property (nonatomic, strong) UILabel *versionLabel;
@end

#ifndef TWEAK_VERSION
#define TWEAK_VERSION @"0.3.0"
#endif