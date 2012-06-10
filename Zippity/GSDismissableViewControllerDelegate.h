//
//  GSDismissableViewControllerDelegate.h
//  Zippity
//
//  Created by Simon Whitaker on 10/06/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol GSDismissableViewControllerDelegate <NSObject>

- (void)viewControllerShouldDismiss:(UIViewController*)viewController wasCancelled:(BOOL)wasCancelled;

@end
