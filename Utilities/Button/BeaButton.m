#import "BeaButton.h"

@implementation BeaButton
+ (instancetype)downloadButton {
    BeaButton *downloadButton = [BeaButton buttonWithType:UIButtonTypeCustom];
    [downloadButton setTitle:@"" forState:UIControlStateNormal];

	UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
	UIImage *downloadImage = [UIImage systemImageNamed:@"arrow.down.circle.fill" withConfiguration:config];
	downloadImage = [downloadImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

	// Add semi-transparent background for visibility on any image
	downloadButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
	downloadButton.layer.cornerRadius = 14; // Half of 28pt button size
	
	// Shadow settings - masksToBounds must be NO for shadow to show
	downloadButton.layer.shadowColor = [[UIColor blackColor] CGColor];
    downloadButton.layer.shadowOffset = CGSizeMake(0, 1);
    downloadButton.layer.shadowRadius = 3;
    downloadButton.layer.shadowOpacity = 0.5;
	downloadButton.layer.masksToBounds = NO;
	downloadButton.clipsToBounds = NO;

    [downloadButton setImage:downloadImage forState:UIControlStateNormal];
    [downloadButton setTintColor:[UIColor whiteColor]];
	downloadButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	downloadButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    downloadButton.translatesAutoresizingMaskIntoConstraints = NO;
	
	// Ensure button is always interactive and visible
	downloadButton.userInteractionEnabled = YES;
	downloadButton.alpha = 1.0;
	
    [downloadButton addTarget:[BeaDownloader class] action:@selector(downloadImage:) forControlEvents:UIControlEventTouchUpInside];
    
    return downloadButton;
}

- (void)toggleVisibilityWithGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if ((gestureRecognizer.numberOfTouches < 2 && [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) || gestureRecognizer.state == 3) {
        if (gestureRecognizer.state == 2) return;
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 1;
        }];
    } else if ((gestureRecognizer.state == 1 || gestureRecognizer.state == 2)) {
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 0;
        }];
    }
}
@end