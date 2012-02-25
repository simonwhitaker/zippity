//
//  GSImagePreviewController.m
//  Zippity
//
//  Created by Simon Whitaker on 25/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSImagePreviewController.h"

@interface GSImagePreviewController ()

@end

@implementation GSImagePreviewController

@synthesize imageFile=_imageFile;

- (id)init
{
    self = [super init];
    if (self) {
        self.wantsFullScreenLayout = YES;
    }
    return self;
}

- (void)loadView
{
    // If you create your views manually, you MUST override this method and use it to create your views.
    // If you use Interface Builder to create your views, then you must NOT override this method.
    CGRect initialFrame = CGRectMake(0, 0, 320, 480);

    UIImageView *iv = [[UIImageView alloc] initWithFrame:initialFrame];
    iv.backgroundColor = [UIColor blackColor];
    iv.image = [UIImage imageWithContentsOfFile:self.imageFile.url.path];
    iv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    iv.contentMode = UIViewContentModeScaleAspectFit;
    
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleChromeVisibility)];
    [iv addGestureRecognizer:gr];
    iv.userInteractionEnabled = YES;
    
    self.view = iv;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)toggleChromeVisibility {
    CGFloat alpha;
    if (self.navigationController.navigationBar.alpha < 0.05) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        alpha = 1.0;
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        alpha = 0.0;
    }
    
    [UIView animateWithDuration:0.35 animations:^{
        self.navigationController.navigationBar.alpha = alpha;
    }];
}

@end
