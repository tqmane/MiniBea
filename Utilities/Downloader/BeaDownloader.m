#import "BeaDownloader.h"

@implementation BeaDownloader
+ (void)downloadImage:(id)sender {
	UIButton *button = (UIButton *)sender;
	UIImageView *imageView = nil;

    UIView *container = button.superview;
    while (container && ![container isKindOfClass:[UIWindow class]] && !imageView) {
        NSMutableArray *foundImageViews = [NSMutableArray array];
        [self findViewsOfClass:@"SDAnimatedImageView" inView:container result:foundImageViews];
        imageView = [self visibleTopmostImageViewFrom:foundImageViews relativeTo:button.window];
        container = container.superview;
    }

    if (!imageView && button.window) {
        NSMutableArray *windowImages = [NSMutableArray array];
        [self findViewsOfClass:@"SDAnimatedImageView" inView:button.window result:windowImages];
        imageView = [self visibleTopmostImageViewFrom:windowImages relativeTo:button.window];
    }

	if (imageView) {
		UIImage *imageToSave = imageView.image;
		UIImageWriteToSavedPhotosAlbum(imageToSave, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)button);
	} else {
		NSLog(@"[Bea] Could not find image view to save.");
	}
}

+ (void)findViewsOfClass:(NSString *)className inView:(UIView *)view result:(NSMutableArray *)result {
    // Check if this view is of the target class
    if ([[[view class] description] isEqualToString:className]) {
        [result addObject:view];
    }

    // since we have a DoubleMediaView, there are two SDAnimatedImageViews but only one is visible at a time
    // since the SDAnimatedImageView doesn't get hidden but instead their parent's parent's parent superview
    // we need to check if the view is hidden and if it is, we don't need to check its subviews
    if ([view isHidden] || [view alpha] == 0) {
        return;
    }
    // Recursively check all subviews
    for (UIView *subview in view.subviews) {
        [self findViewsOfClass:className inView:subview result:result];
    }
}

+ (UIImageView *)visibleTopmostImageViewFrom:(NSArray<UIImageView *> *)candidates relativeTo:(UIWindow *)window {
    UIImageView *best = nil;
    CGFloat bestScore = -CGFLOAT_MAX;

    for (UIImageView *candidate in candidates) {
        if (!candidate.image) continue;
        if (candidate.isHidden || candidate.alpha < 0.05) continue;

        CGRect frameInWindow = [candidate.superview convertRect:candidate.frame toView:window];
        CGFloat visibleArea = fabs(frameInWindow.size.width * frameInWindow.size.height);
        if (visibleArea <= 0.0) continue;

        // Depth = number of superviews to window; lower depth => more foreground
        NSInteger depth = 0;
        UIView *walker = candidate;
        while (walker && walker != window) {
            depth++;
            walker = walker.superview;
        }
        CGFloat score = visibleArea - (depth * 10.0f);
        if (score > bestScore) {
            bestScore = score;
            best = candidate;
        }
    }
    return best;
}

+ (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"[Bea]Error saving image: %@", error.localizedDescription);
    } else {
        UIButton *button = (__bridge UIButton *)contextInfo;
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
}
@end
