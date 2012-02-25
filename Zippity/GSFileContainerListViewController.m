//
//  GSFileListViewController.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSFileContainerListViewController.h"
#import "GSAppDelegate.h"
#import <QuickLook/QuickLook.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "GSImagePreviewController.h"

#define IN_BETA 1

@interface GSFileContainerListViewController()

- (void)handleContentsReloaded:(NSNotification*)notification;
- (void)handleContentsFailedToReload:(NSNotification*)notification;

- (void)handleShareButton:(id)sender;

@end

@implementation GSFileContainerListViewController

@synthesize container=_container;
@synthesize isRoot=isRoot;

- (id)initWithContainer:(GSFileWrapper*)container
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.container = container;
        self.isRoot = NO;
        self.wantsFullScreenLayout = NO;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    if (self.isRoot) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                               target:self
                                                                                               action:@selector(handleShareButton:)];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.container.visited = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

#pragma mark - Custom accessors

- (NSDateFormatter*)subtitleDateFormatter
{
    if (_subtitleDateFormatter == nil) {
        _subtitleDateFormatter = [[NSDateFormatter alloc] init];
        _subtitleDateFormatter.timeStyle = NSDateFormatterNoStyle;
        _subtitleDateFormatter.dateStyle = NSDateFormatterMediumStyle;
    }
    return _subtitleDateFormatter;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#ifdef IN_BETA
    if (self.isRoot) return 2;
#endif
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#ifdef IN_BETA
    if (self.isRoot && section == 1) return 1;
#endif
    
    return self.container.fileWrappers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
#ifdef IN_BETA
    if (self.isRoot && indexPath.section == 1) {
        NSString *cellID = @"DevNotes";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        }
        cell.textLabel.text = @"Info for beta testers";
        cell.imageView.image = [UIImage imageNamed:@"safari-icon.png"];
        return cell;
    }
#endif
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    GSFileWrapper *wrapper = [self.container fileWrapperAtIndex:indexPath.row];
    cell.textLabel.text = wrapper.displayName;
    
    if (wrapper.isRegularFile) {
        if (self.isRoot) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Opened on %@", [self.subtitleDateFormatter stringFromDate:wrapper.attributes.fileModificationDate]];
        } else {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, last modified on %@", wrapper.humanFileSize, [self.subtitleDateFormatter stringFromDate:wrapper.attributes.fileModificationDate]];
        }
    }
    
    if (wrapper.isContainer || (wrapper.documentInteractionController && [QLPreviewController canPreviewItem:wrapper.url])) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    cell.imageView.image = wrapper.icon;
    
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return self.isRoot && indexPath.section == 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSError *error = nil;
        [self.container removeItemAtIndex:indexPath.row error:&error];
        if (error) {
            NSLog(@"Error on deleting object at row %u of %@: %@, %@", indexPath.row, self, error, error.userInfo);
        } else {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }   
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
#ifdef IN_BETA
    if (self.isRoot && indexPath.section == 1) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://dl.dropbox.com/u/363683/zippity-testers.md"]];
        return;
    }
#endif
    
    GSFileWrapper *wrapper = [self.container fileWrapperAtIndex:indexPath.row];
    
    if (wrapper.isImageFile) {
        GSImagePreviewController *vc = [[GSImagePreviewController alloc] init];
        vc.imageFile = wrapper;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (wrapper.isContainer) {
        GSFileContainerListViewController *vc = [[GSFileContainerListViewController alloc] initWithContainer:wrapper];
        vc.tableView.delegate = vc;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (wrapper.documentInteractionController && [QLPreviewController canPreviewItem:wrapper.url]) {
        wrapper.documentInteractionController.delegate = self;
        [wrapper.documentInteractionController presentPreviewAnimated:YES];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Not yet!"
                                                      message:@"Zippity doesn't recognise this file type yet. Please try again after the next release."
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
        [av show];
    }
}

- (void)setContainer:(GSFileWrapper*)container
{
    if (_container != container) {
        // Remove old notification observers
        if (_container) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:GSFileWrapperContainerDidReloadContents
                                                          object:_container];
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:GSFileWrapperContainerDidFailToReloadContents
                                                          object:_container];
        }
        
        // Switch container ivar to new container
        _container = container;

        // Set up new notification observers
        if (_container) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleContentsReloaded:)
                                                         name:GSFileWrapperContainerDidReloadContents
                                                       object:_container];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleContentsFailedToReload:)
                                                         name:GSFileWrapperContainerDidFailToReloadContents
                                                       object:_container];
            self.title = container.name;
        }
    }
}

#pragma mark - UIDocumentInteractionController delegate

- (UIViewController*)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self.navigationController;
}

#pragma mark - MFMailComposeViewController delegate methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIActionSheet delegate methods

#define kEmailButtonLabel @"Email"

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(kEmailButtonLabel, nil)]) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
            
            CFStringRef utiStringRef = (__bridge CFStringRef)self.container.documentInteractionController.UTI;
            
            // UTTypeCopy... retains its return value (contains the word "copy"), so we
            // need to balance this with a release. We either do that manually by retaining
            // a CFStringRef and calling CFRelease() on it, or we transfer responsility for
            // memory management to ARC by using __bridge_transfer and let ARC sort it out.
            // See http://www.mikeash.com/pyblog/friday-qa-2011-09-30-automatic-reference-counting.html
            // for more on this.
            NSString *mimeType = (__bridge_transfer NSString*)UTTypeCopyPreferredTagWithClass(utiStringRef,
                                                                                              kUTTagClassMIMEType);
            if (!mimeType) {
                mimeType = @"application/octet-stream";
            }
            
            NSLog(@"Sending an email with MIME type %@", mimeType);
            
            [mailComposer addAttachmentData:[NSData dataWithContentsOfURL:self.container.url]
                                   mimeType:mimeType
                                   fileName:self.container.name];
            mailComposer.mailComposeDelegate = self;
            [self presentModalViewController:mailComposer animated:YES];
        } else {
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                         message:@"You can't send mail on this device - do you need to set up an email account?"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
            [av show];
        }
    }
}

#pragma mark - UI event handlers

- (void)handleShareButton:(id)sender
{
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Share %@", @"Share label in sharing action sheet"), self.container.name]
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button in sharing action sheet")
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:NSLocalizedString(kEmailButtonLabel, @"Email button label in action sheet"), nil];
    [as showInView:self.view];
}

#pragma mark - Notification handlers

- (void)handleContentsReloaded:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)handleContentsFailedToReload:(NSNotification *)notification
{
    NSLog(@"Contents failed to reload");
    // TODO: show error to user
}

@end
