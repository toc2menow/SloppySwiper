//
//  SSWAnimator.m
//
//  Created by Arkadiusz Holko http://holko.pl on 29-05-14.
//

#import "SSWAnimator.h"

UIViewAnimationOptions const SSWNavigationTransitionCurve = 7 << 16;


@implementation UIView (TransitionShadow)
- (void)addLeftSideShadowWithFading
{
    CGFloat shadowWidth = 4.0f;
    CGFloat shadowVerticalPadding = -20.0f; // negative padding, so the shadow isn't rounded near the top and the bottom
    CGFloat shadowHeight = CGRectGetHeight(self.frame) - 2 * shadowVerticalPadding;
    CGRect shadowRect = CGRectMake(-shadowWidth, shadowVerticalPadding, shadowWidth, shadowHeight);
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:shadowRect];
    self.layer.shadowPath = [shadowPath CGPath];
    self.layer.shadowOpacity = 0.2f;
    
    // fade shadow during transition
    CGFloat toValue = 0.0f;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    animation.fromValue = @(self.layer.shadowOpacity);
    animation.toValue = @(toValue);
    [self.layer addAnimation:animation forKey:nil];
    self.layer.shadowOpacity = toValue;
}
@end


@interface SSWAnimator()
@property (weak, nonatomic) UIViewController *toViewController;
@end

@implementation SSWAnimator

- (UIImage *)screenShot:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, [[UIScreen mainScreen] scale]);
    // Use presentationlayer to capture gif
    CGContextRef context = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:context];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    return image;
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    // Approximated lengths of the default animations.
    return [transitionContext isInteractive] ? 0.25f : 0.5f;
}

// Tries to animate a pop transition similarly to the default iOS' pop transition.
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *toView = toViewController.view;
    //    UIView *fromView = fromViewController.view;
    UIView *fromView = [fromViewController.view snapshotViewAfterScreenUpdates:NO];
    [fromView addLeftSideShadowWithFading];
    
    UITabBarController *tabBarController = toViewController.tabBarController;
    UIView *tabbarView = tabBarController.tabBar;
    
    CGRect toFrame = toView.frame;
    CGRect tabbarFrame = tabbarView.frame;
    CGRect fromFrame = fromView.frame;
    BOOL toNavigationBarHidden = toViewController.navigationController.navigationBarHidden;
    BOOL fromNavigationBarHidden = fromViewController.navigationController.navigationBarHidden;
    if (toNavigationBarHidden != fromNavigationBarHidden) {
        if (toNavigationBarHidden) {
            toFrame.origin.y += 64;
            toFrame.size.height -= 64;
            toView.frame = toFrame;
        } else {
            toFrame.origin.y -= 64;
            toFrame.size.height += 64;
            toView.frame = toFrame;
        }
    }
    
    toFrame.origin.x = -toFrame.size.width * 0.25;
    toView.frame = toFrame;
    
    tabbarView.frame = CGRectMake(toFrame.origin.x, tabbarFrame.origin.y, tabbarFrame.size.width, tabbarFrame.size.height);
    [[transitionContext containerView] addSubview:toView];
    [[transitionContext containerView] addSubview:tabbarView];
    [[transitionContext containerView] addSubview:fromView];
    
    [UIView animateWithDuration:0.25f animations:^{
        toView.frame = CGRectMake(0, toFrame.origin.y, toFrame.size.width, toFrame.size.height);
        fromView.frame = CGRectMake(toFrame.size.width, fromFrame.origin.y, fromFrame.size.width, fromFrame.size.height);
        tabbarView.frame = CGRectMake(0, tabbarFrame.origin.y, tabbarFrame.size.width, tabbarFrame.size.height);
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        tabbarView.frame = CGRectMake(0, tabbarFrame.origin.y, tabbarFrame.size.width, tabbarFrame.size.height);
        [tabBarController.view addSubview:tabbarView];
        [fromView removeFromSuperview];
    }];
    self.toViewController = toViewController;
}

- (void)animationEnded:(BOOL)transitionCompleted
{
    // restore the toViewController's transform if the animation was cancelled
    if (!transitionCompleted) {
        self.toViewController.view.transform = CGAffineTransformIdentity;
    }
}

@end
