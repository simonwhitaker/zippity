//
//  ZPAboutViewController.h
//  Zippity
//
//  Created by Simon Whitaker on 23/03/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

@protocol ZPAboutViewControllerDelegate;

enum {
    ZPAboutAlertViewTypeUnknown,
    ZPAboutAlertViewTypeSelectTwitterAccount
};

enum {
    ZPContactOptionsTwitter,
    ZPContactOptionsEmail,
    ZPContactOptionsWebsite
};

@interface ZPAboutViewController : UIViewController <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate>
@property (nonatomic, weak) id<ZPAboutViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, weak) IBOutlet UITableView *contactOptionsTable;
- (IBAction)handleCloseButton:(id)sender;
- (IBAction)visitHicksDesign:(id)sender;
@end

@protocol ZPAboutViewControllerDelegate <NSObject>
- (void)aboutViewControllerShouldDismiss:(ZPAboutViewController*)aboutViewController;
@end
