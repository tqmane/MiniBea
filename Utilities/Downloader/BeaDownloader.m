#import "BeaDownloader.h"

@implementation BeaDownloader
+ (void)downloadImage:(id)sender {
	UIButton *button = (UIButton *)sender;
	UIImageView *imageView = nil;

    UIView *superview = button.superview;

    // First check if superview itself is an ImageView (SDAnimatedImageView hook case)
    if ([superview isKindOfClass:[UIImageView class]]) {
        imageView = (UIImageView *)superview;
        NSLog(@"[MiniBea] Download: Found image from parent ImageView");
    }
    
    // If parent isn't an ImageView, search for SDAnimatedImageView in hierarchy
    if (!imageView || !imageView.image) {
        NSMutableArray *foundImageViews = [NSMutableArray array];
        
        // For BeReal 4.58.0 - DoubleMediaViewUIKitLegacyImpl structure
        // Search directly in the superview for SDAnimatedImageView
        [self findViewsOfClass:@"SDAnimatedImageView" inView:superview result:foundImageViews];
        
        // If not found, try the old structure
        if ([foundImageViews count] == 0) {
            UIView *root = superview.subviews.firstObject.subviews.firstObject;
            [self findViewsOfClass:@"SDAnimatedImageView" inView:root result:foundImageViews];
        }
        
        // Try alternative image view classes
        if ([foundImageViews count] == 0) {
            [self findViewsOfClass:@"UIImageView" inView:superview result:foundImageViews];
        }

        imageView = foundImageViews.firstObject;
        NSLog(@"[MiniBea] Download: Found image from search (%lu results)", (unsigned long)[foundImageViews count]);
    }

	if (imageView && imageView.image) {
		UIImage *imageToSave = imageView.image;
		NSLog(@"[MiniBea] Download: Saving image %@", NSStringFromCGSize(imageToSave.size));
		UIImageWriteToSavedPhotosAlbum(imageToSave, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)button);
	} else {
        NSLog(@"[MiniBea] Download: No image found to save");
    }
}

+ (void)findViewsOfClass:(NSString *)className inView:(UIView *)view result:(NSMutableArray *)result {
    if (!view) return;
    
    // Check if this view is of the target class
    NSString *viewClassName = NSStringFromClass([view class]);
    if ([viewClassName isEqualToString:className] || [viewClassName containsString:className]) {
        [result addObject:view];
    }

    // since we have a DoubleMediaView, there are two SDAnimatedImageViews but only one is visible at a time
    // since the SDAnimatedImageView doesn't get hidden but instead their parent's parent's parent superview
    // we need to check if the view is hidden and if it is, we don't need to check its subviews
    if ([view alpha] == 0 || [view isHidden]) {
        return;
    }
    // Recursively check all subviews
    for (UIView *subview in view.subviews) {
        [self findViewsOfClass:className inView:subview result:result];
    }
}

+ (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            NSLog(@"[Bea]Error saving image: %@", error.localizedDescription);
        } else {
            UIButton *button = (__bridge UIButton *)contextInfo;
            // Check if button is still valid/visible effectively isn't possible easily with void*, 
            // but dispatch_async helps if checked against nil (though bridge cast doesn't nil check)
            if (!button) return;

            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:19];
            UIImage *checkmarkImage = [UIImage systemImageNamed:@"checkmark.circle.fill" withConfiguration:config];
            [UIView transitionWithView:button duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [button setImage:checkmarkImage forState:UIControlStateNormal];
            [button setEnabled:NO]; 
            [button.imageView setTintColor:[UIColor colorWithRed:122.0/255.0 green:255.0/255.0 blue:108.0/255.0 alpha:1.0]];} completion:nil];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                UIImage *downloadImage = [UIImage systemImageNamed:@"arrow.down.circle.fill" withConfiguration:config];
                [UIView transitionWithView:button duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                    [button setImage:downloadImage forState:UIControlStateNormal];
                    [button.imageView setTintColor:[UIColor whiteColor]];
                    [button setEnabled:YES];
                } completion:nil];
            });
        }
    });
}
@end