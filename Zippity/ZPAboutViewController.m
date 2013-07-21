//
//  ZPAboutViewController.m
//  Zippity
//
//  Created by Simon Whitaker on 23/03/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPAboutViewController.h"
#import "GSSmokedInfoView.h"
#import <Social/Social.h>

@implementation ZPAboutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (isIOS6OrBelow) {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"rough_diagonal.png"]];
    }
    
    NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *versionStr = [NSString stringWithFormat:NSLocalizedString(@"Version %@ (%@)", @"Version string. Placeholders are replaced by version number and build number."), 
                            [appInfo objectForKey:@"CFBundleShortVersionString"], 
                            [appInfo objectForKey:@"CFBundleVersion"]];
    self.versionLabel.text = versionStr;
    
    self.twitterButton.accessibilityLabel = NSLocalizedString(@"Follow @zippityapp on Twitter", @"Accessibility text for visually impaired users, prompting the user to follow @zippityapp on Twitter");
    self.emailButton.accessibilityLabel = NSLocalizedString(@"Email info@goosoftware.co.uk", @"Accessibility text for visually impaired users, prompting the user to email us");
    self.websiteButton.accessibilityLabel = NSLocalizedString(@"Visit www.zippityapp.co.uk", @"Accessibility text for visually impaired users, prompting the user to visit Zippity's website");
    
    self.title = NSLocalizedString(@"About Zippity", @"Title for the About view");
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleCloseButton:)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (isIpad) {
        return YES;
    }
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)followOnTwitterDidSucceed 
{
    GSSmokedInfoView *iv = [[GSSmokedInfoView alloc] initWithMessage:NSLocalizedString(@"You're now following @zippityapp!",
                                                                                       @"Message shown when the user successfully follows @zippityapp on Twitter")
                                                          andTimeout:2.0];
    [iv show];
}

- (void)followOnTwitterDidFail
{
    GSSmokedInfoView *iv = [[GSSmokedInfoView alloc] initWithMessage:NSLocalizedString(@"Error following @zippityapp",
                                                                                       @"Message shown when there's an error following @zippityapp on Twitter")
                                                          andTimeout:2.0];
    [iv show];
}

- (void)followOnTwitter
{
    // Assumes that the user has already given us permission to access their
    // Twitter accounts. 
    // Must call [ACAccountStore requestAccessToAccountsWithType:withCompletionHandler:]
    // first and only call this method on success.
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    NSArray *accounts = [accountStore accountsWithAccountType:accountType];
    
    if (accounts.count == 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/zippityapp"]];
    } else if (accounts.count == 1) {
        [self followOnTwitterUsingAccount:[accounts objectAtIndex:0]];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Choose account", @"Title for a message box prompting the user to choose a Twitter account from which to follow @zippityapp")
                                                     message:NSLocalizedString(@"Which Twitter account do you want to follow @zippityapp from?", 
                                                                               @"Message asking the user which of their Twitter accounts they'd like to follow @zippityapp from")
                                                    delegate:self
                                           cancelButtonTitle:nil
                                           otherButtonTitles:nil];
        
        int cancelButtonIndex = 0;
        for (ACAccount *account in accounts) {
            [av addButtonWithTitle:account.username];
            cancelButtonIndex++;
            if (cancelButtonIndex == 5) {
                break;
            }
        }
        [av addButtonWithTitle:@"Cancel"];
        [av setCancelButtonIndex:cancelButtonIndex];
        av.tag = ZPAboutAlertViewTypeSelectTwitterAccount;
        [av show];
    }

}

- (void)followOnTwitterUsingAccount:(ACAccount*)account
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setValue:@"zippityapp" forKey:@"screen_name"];
    [parameters setValue:@"true" forKey:@"follow"];
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/create.json"];
    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:url parameters:parameters];

    [postRequest setAccount:account];
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"HTTP response status: %i", urlResponse.statusCode);
        
        if (urlResponse.statusCode >= 400) {
            [self performSelectorOnMainThread:@selector(followOnTwitterDidFail)
                                   withObject:nil
                                waitUntilDone:NO];
        } else {
            [self performSelectorOnMainThread:@selector(followOnTwitterDidSucceed)
                                   withObject:nil
                                waitUntilDone:NO];
        }
    }];
}

#pragma mark - Table view delegate methods

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.contactOptionsTable dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    switch (indexPath.row) {
        case ZPContactOptionsTwitter:
            cell.imageView.image = [UIImage imageNamed:@"210-twitterbird.png"];
            cell.textLabel.text = NSLocalizedString(@"Follow @zippityapp", @"Button prompting the user to follow @zippityapp on Twitter");
            cell.textLabel.accessibilityLabel = NSLocalizedString(@"Follow @zippityapp on Twitter", @"Accessibility text for visually impaired users, prompting the user to follow @zippityapp on Twitter");
            break;
        case ZPContactOptionsEmail:
            cell.imageView.image = [UIImage imageNamed:@"18-envelope.png"];
            cell.textLabel.text = @"info@goosoftware.co.uk";
            cell.textLabel.accessibilityLabel = NSLocalizedString(@"Email info@goosoftware.co.uk", @"Accessibility text for visually impaired users, prompting the user to email us");
            break;
        case ZPContactOptionsWebsite:
            cell.imageView.image = [UIImage imageNamed:@"71-compass.png"];
            cell.textLabel.text = @"www.zippityapp.co.uk";
            cell.textLabel.accessibilityLabel = NSLocalizedString(@"Visit www.zippityapp.co.uk", @"Accessibility text for visually impaired users, prompting the user to visit Zippity's website");
            break;
    }
    
    return cell;
}
 */


#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    if (alertView.tag == ZPAboutAlertViewTypeSelectTwitterAccount) {
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        NSArray *accounts = [accountStore accountsWithAccountType:accountType];

        if (buttonIndex >= 0 && buttonIndex < accounts.count) {
            ACAccount *twitterAccount = [accounts objectAtIndex:buttonIndex];
            [self followOnTwitterUsingAccount:twitterAccount];
        }
    }
}

#pragma mark - UI event handlers

- (IBAction)handleCloseButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(viewControllerShouldDismiss:wasCancelled:)]) {
        [self.delegate viewControllerShouldDismiss:self wasCancelled:NO];
    }
}

- (void)handleEmailButton:(id)sender
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *vc = [[MFMailComposeViewController alloc] init];
        vc.mailComposeDelegate = self;
        [vc setSubject:@"Zippity"];
        [vc setToRecipients:[NSArray arrayWithObject:@"info@goosoftware.co.uk"]];
        [self presentViewController:vc animated:YES completion:NULL];
    } else {
        NSString *message = NSLocalizedString(@"You don't have an email account configured. You can set one up in the main Settings app.",
                                              @"Message shown to a user when they try to email a file but have not set up an email account on their iPhone.");
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:[[NSBundle mainBundle] localizedStringForKey:@"Error" value:nil table:nil]
                                                     message:message
                                                    delegate:nil
                                           cancelButtonTitle:[[NSBundle mainBundle] localizedStringForKey:@"Cancel" value:nil table:nil]
                                           otherButtonTitles:nil];
        [av show];
    }
}

- (void)handleTwitterButton:(id)sender
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        if (granted) {
            [self performSelectorOnMainThread:@selector(followOnTwitter)
                                   withObject:nil
                                waitUntilDone:NO];
        }
    }];
}

- (void)handleWebsiteButton:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.zippityapp.co.uk/"]];
}

- (IBAction)visitHicksDesign:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.hicksdesign.co.uk/"]];
}

#pragma mark - Mail compose view delegate methods

- (void)mailComposeController:(MFMailComposeViewController *)controller 
          didFinishWithResult:(MFMailComposeResult)result 
                        error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
