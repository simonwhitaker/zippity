//
//  GSStatusBarViewController.h
//
//  Created by Simon Whitaker on 13/11/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GSStatusBarViewController : UIViewController

@property (nonatomic, strong) UIViewController *contentViewController;
@property (nonatomic, readonly) BOOL isDisplayingStatusBar;

- (id)initWithContentViewController:(UIViewController *)contentViewController;

/* Set timeout to 0 to have the message persist until the next message arrives. */
- (void)showMessage:(NSString *)message withTimeout:(NSTimeInterval)timeout;

/* Dismiss the status bar, discarding any messages */
- (void)dismissAnimated:(BOOL)animated;

- (void)showProgressViewWithProgress:(CGFloat)progress;
- (void)hideProgressView;

@end
