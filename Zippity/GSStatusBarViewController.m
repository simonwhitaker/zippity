//
//  GSStatusBarViewController.m
//
//  Created by Simon Whitaker on 13/11/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSStatusBarViewController.h"
#import <QuartzCore/QuartzCore.h>

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
const static CGFloat kStatusBarShadowOffset = 4.0;
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
    
    CGRect labelFrame = CGRectMake(kStatusLabelPadding.width,
                                   self.view.frame.size.height - kStatusLabelPadding.height - kStatusLabelHeight,
                                   self.view.frame.size.width - kStatusLabelPadding.width * 2,
                                   kStatusLabelHeight);
    UILabel *statusLabel = [[UILabel alloc] initWithFrame:labelFrame];
    statusLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    statusLabel.backgroundColor = [UIColor clearColor];
    statusLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    statusLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    statusLabel.shadowOffset = CGSizeMake(0.0, 1.0);
    statusLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13.0];
    [self.view insertSubview:statusLabel atIndex:0];
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
        v.layer.shadowRadius = 2.0;
    }
}

- (void)showMessage:(NSString *)message withTimeout:(NSTimeInterval)timeout
{
    [self.messageQueue addObject:[GSMessage messageWithText:message andTimeout:timeout]];
    
    if (!self.isServicingQueue && self.serviceQueueTimer == nil)
        [self serviceQueue];
}

- (void)serviceQueue
{
    [self.serviceQueueTimer invalidate];
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
    }];

}

- (void)hideStatusBar
{
    if (!self.isDisplayingStatusBar)
        return;
    
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
