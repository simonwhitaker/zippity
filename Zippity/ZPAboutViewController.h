//
//  ZPAboutViewController.h
//  Zippity
//
//  Created by Simon Whitaker on 23/03/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <Accounts/Accounts.h>
#import "GSDismissableViewControllerDelegate.h"

enum {
    ZPAboutAlertViewTypeUnknown,
    ZPAboutAlertViewTypeSelectTwitterAccount
};

@interface ZPAboutViewController : UIViewController <UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, weak) id<GSDismissableViewControllerDelegate> delegate;

@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@property (nonatomic, weak) IBOutlet UIButton *twitterButton;
@property (nonatomic, weak) IBOutlet UIButton *websiteButton;
@property (nonatomic, weak) IBOutlet UIButton *emailButton;

- (IBAction)handleCloseButton:(id)sender;
- (IBAction)handleTwitterButton:(id)sender;
- (IBAction)handleWebsiteButton:(id)sender;
- (IBAction)handleEmailButton:(id)sender;
- (IBAction)visitHicksDesign:(id)sender;
@end

