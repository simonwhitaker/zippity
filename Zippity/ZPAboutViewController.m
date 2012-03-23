//
//  ZPAboutViewController.m
//  Zippity
//
//  Created by Simon Whitaker on 23/03/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPAboutViewController.h"
#import "GSSmokedInfoView.h"

@interface ZPAboutViewController ()

- (void)followOnTwitter;
- (void)followOnTwitterUsingAccount:(ACAccount*)account;
- (void)followOnTwitterDidSucceed;
- (void)followOnTwitterDidFail;

@end

@implementation ZPAboutViewController

@synthesize delegate = _delegate;
@synthesize navigationBar = _navigationBar;
@synthesize contactOptionsTable = _contactOptionsTable;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"rough_diagonal.png"]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)followOnTwitterDidSucceed 
{
    GSSmokedInfoView *iv = [[GSSmokedInfoView alloc] initWithMessage:@"You're now following @zippityapp!"
                                                          andTimeout:2.0];
    [iv show];
}

- (void)followOnTwitterDidFail
{
    GSSmokedInfoView *iv = [[GSSmokedInfoView alloc] initWithMessage:@"Error following @zippityapp"
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
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Choose account"
                                                     message:@"Which Twitter account do you want to follow @zippityapp from?"
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
    
    TWRequest *postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/1/friendships/create.json"]
                                                 parameters:parameters
                                              requestMethod:TWRequestMethodPOST];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case ZPContactOptionsEmail:
        {
            if ([MFMailComposeViewController canSendMail]) {
                MFMailComposeViewController *vc = [[MFMailComposeViewController alloc] init];
                vc.mailComposeDelegate = self;
                [vc setSubject:@"Zippity"];
                [vc setToRecipients:[NSArray arrayWithObject:@"info@goosoftware.co.uk"]];
                [self presentModalViewController:vc animated:YES];
            } else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Email Not Configured"
                                                             message:@"You don't have an email account configured. You can set one up in the main Settings app"
                                                            delegate:nil
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:nil];
                [av show];
            }
            break;
        }
        case ZPContactOptionsWebsite:
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.zippityapp.co.uk/"]];
            break;
        }
        case ZPContactOptionsTwitter:
        {
            ACAccountStore *accountStore = [[ACAccountStore alloc] init];
            ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
            [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
                if (granted) {
                    [self performSelectorOnMainThread:@selector(followOnTwitter)
                                           withObject:nil
                                        waitUntilDone:NO];
                }
            }];
            break;
        }
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
}

#pragma mark - Table view data source methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

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
            cell.textLabel.text = @"Follow @zippityapp";
            cell.textLabel.accessibilityLabel = @"Follow @zippityapp on Twitter";
            break;
        case ZPContactOptionsEmail:
            cell.imageView.image = [UIImage imageNamed:@"18-envelope.png"];
            cell.textLabel.text = @"info@goosoftware.co.uk";
            cell.textLabel.accessibilityLabel = @"Email info@goosoftware.co.uk";
            break;
        case ZPContactOptionsWebsite:
            cell.imageView.image = [UIImage imageNamed:@"71-compass.png"];
            cell.textLabel.text = @"www.zippityapp.co.uk";
            cell.textLabel.accessibilityLabel = @"Visit www.zippity.co.uk";
            break;
    }
    
    return cell;
}

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
    if ([self.delegate respondsToSelector:@selector(aboutViewControllerShouldDismiss:)]) {
        [self.delegate aboutViewControllerShouldDismiss:self];
    }
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
    [self dismissModalViewControllerAnimated:YES];
}

@end
