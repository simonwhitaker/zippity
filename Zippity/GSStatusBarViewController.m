//
//  GSStatusBarViewController.m
//
//  Created by Simon Whitaker on 13/11/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSStatusBarViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "GSProgressView.h"

/* GSMessage: private class implementing a simple message struct. */

@interface GSMessage : NSObject
@property (copy, nonatomic) NSString *text;
@property (nonatomic) NSTimeInterval timeout;
+ (GSMessage *)messageWithText:(NSString*)text andTimeout:(NSTimeInterval)timeout;
@end

@implementation GSMessage
+ (GSMessage *)messageWithText:(NSString*)text andTimeout:(NSTimeInterval)timeout
{
    GSMessage *message = [[GSMessage alloc] init];
    message.text = text;
    message.timeout = timeout;
    return message;
}
@end

/* End of GSMessage */

@interface GSStatusBarViewController ()
@property (strong, nonatomic) NSMutableArray *messageQueue;
@property (weak, nonatomic) UILabel *statusLabel;
@property (weak, nonatomic) GSProgressView *progressView;
@property (strong, nonatomic) NSTimer *serviceQueueTimer;
@property (nonatomic) BOOL isDisplayingStatusBar;
@property (nonatomic) BOOL isServicingQueue;
- (void)serviceQueue;
- (void)showStatusBar;
- (void)hideStatusBar;
@end

@implementation GSStatusBarViewController

const static CGSize kStatusLabelPadding = { 5.0, 5.0 };
const static CGFloat kStatusLabelHeight = 16.0;
const static CGSize kStatusProgressIndicatorSize = { 14.0, 14.0 };
const static CGFloat kStatusBarShadowOffset = 2.0;
const static CGFloat kStatusBarShadowRadius = 2.0;
const static CGFloat kStatusMessageFadeOutAnimationDuration = 0.1;
const static CGFloat kStatusMessageFadeInAnimationDuration = 0.05;

- (id)initWithContentViewController:(UIViewController *)contentViewController
{
    self = [super init];
    if (self) {
        self.contentViewController = contentViewController;
        self.messageQueue = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    [self.serviceQueueTimer invalidate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.000];
    
    CGFloat containerHeight = kStatusLabelHeight + kStatusLabelPadding.height * 2;
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                     self.view.frame.size.height - containerHeight,
                                                                     self.view.frame.size.width,
                                                                     containerHeight)];
    containerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    containerView.backgroundColor = [UIColor clearColor];
    
    CGFloat originX = kStatusLabelPadding.width * 2 + kStatusProgressIndicatorSize.width;
    CGRect labelFrame = CGRectMake(originX,
                                   kStatusLabelPadding.height,
                                   containerView.frame.size.width - kStatusLabelPadding.width - originX,
                                   containerView.frame.size.height - kStatusLabelPadding.height * 2);

    UILabel *statusLabel = [[UILabel alloc] initWithFrame:labelFrame];
    statusLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    statusLabel.backgroundColor = [UIColor clearColor];
    statusLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    statusLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    statusLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    statusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13.0];
    [containerView addSubview:statusLabel];
    
    GSProgressView *progressIndicator = [[GSProgressView alloc] initWithFrame:CGRectMake(kStatusLabelPadding.width,
                                                                                         kStatusLabelPadding.height,
                                                                                         kStatusProgressIndicatorSize.width,
                                                                                         kStatusProgressIndicatorSize.height)];
    progressIndicator.color = statusLabel.textColor;
    progressIndicator.progress = 0.6;
    progressIndicator.hidden = YES;
    [containerView addSubview:progressIndicator];
    self.progressView = progressIndicator;
    
    [self.view insertSubview:containerView atIndex:0];
    
    self.statusLabel = statusLabel;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    [self.messageQueue removeAllObjects];
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
    if (contentViewController != _contentViewController) {
        _contentViewController = contentViewController;
        
        _contentViewController.view.frame = self.view.bounds;
        
        [self addChildViewController:contentViewController];
        [self.view addSubview:contentViewController.view];

        UIView *v = self.contentViewController.view;
        v.layer.masksToBounds = NO;
        v.layer.shadowColor = [[UIColor blackColor] CGColor];
        v.layer.shadowOpacity = 0.5;
        v.layer.shadowOffset = CGSizeMake(0, kStatusBarShadowOffset);
        v.layer.shadowRadius = kStatusBarShadowRadius;
    }
}

- (void)showMessage:(NSString *)message withTimeout:(NSTimeInterval)timeout
{
    [self.messageQueue addObject:[GSMessage messageWithText:message andTimeout:timeout]];
    
    if (!self.isServicingQueue && self.serviceQueueTimer == nil)
        [self serviceQueue];
}

- (void)showProgressViewWithProgress:(CGFloat)progress
{
    self.progressView.progress = progress;
    self.progressView.hidden = NO;
}

- (void)hideProgressView
{
    self.progressView.hidden = YES;
}

- (void)serviceQueue
{
    [self.serviceQueueTimer invalidate];
    self.serviceQueueTimer = nil;
    
    self.isServicingQueue = YES;
    
    if ([self.messageQueue count] == 0) {
        [self hideStatusBar];
    } else {
        GSMessage *message = [self.messageQueue objectAtIndex:0];
        [self.messageQueue removeObjectAtIndex:0];

        if (message.text == nil || [message.text isEqualToString:@""]) {
            [self hideStatusBar];
        } else if (self.isDisplayingStatusBar) {
            // Swap the message
            [UIView animateWithDuration:kStatusMessageFadeOutAnimationDuration animations:^{
                self.statusLabel.alpha = 0.0;
            } completion:^(BOOL finished) {
                self.statusLabel.text = message.text;
                [UIView animateWithDuration:kStatusMessageFadeInAnimationDuration animations:^{
                    self.statusLabel.alpha = 1.0;
                }];
            }];
        } else {
            self.statusLabel.text = message.text;
            [self showStatusBar];
        }
        
        if (message.timeout) {
            self.serviceQueueTimer = [NSTimer scheduledTimerWithTimeInterval:message.timeout
                                                                      target:self
                                                                    selector:@selector(serviceQueue)
                                                                    userInfo:nil
                                                                     repeats:NO];
        }
    }
    self.isServicingQueue = NO;
}

- (void)showStatusBar
{
    if (self.isDisplayingStatusBar)
        return;

    [UIView animateWithDuration:0.5 animations:^{
        CGRect r = self.contentViewController.view.frame;
        r.size.height = self.view.bounds.size.height - (kStatusLabelHeight + kStatusLabelPadding.height * 2 + roundf(kStatusBarShadowOffset / 2));
        self.contentViewController.view.frame = r;
    } completion:^(BOOL finished) {
        self.isDisplayingStatusBar = YES;
        self.progressView.hidden = NO;
    }];

}

- (void)hideStatusBar
{
    if (!self.isDisplayingStatusBar)
        return;
    
    self.progressView.hidden = YES;
    [UIView animateWithDuration:0.5 animations:^{
        CGRect r = self.contentViewController.view.frame;
        r.size.height = self.view.bounds.size.height;
        self.contentViewController.view.frame = r;
    } completion:^(BOOL finished) {
        self.statusLabel.text = nil;
        self.isDisplayingStatusBar = NO;
    }];
}

@end
