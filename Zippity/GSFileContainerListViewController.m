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

@interface GSFileContainerListViewController()

- (void)handleContentsReloaded:(NSNotification*)notification;
- (void)handleContentsFailedToReload:(NSNotification*)notification;

- (void)shareSelectedItems;
- (void)deleteSelectedItems;

@end

@implementation GSFileContainerListViewController

@synthesize container=_container;
@synthesize isRoot=isRoot;
@synthesize shareButton=_shareButton;
@synthesize deleteButton=_deleteButton;

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

    NSMutableArray * toolbarButtons = [NSMutableArray array];
    UIBarButtonItem * tempButton;
    tempButton = [[UIBarButtonItem alloc] initWithTitle:@"Share"
                                                  style:UIBarButtonItemStyleBordered
                                                 target:self
                                                 action:@selector(shareSelectedItems)];
    tempButton.width = 80.0;
    [toolbarButtons addObject:tempButton];
    self.shareButton = tempButton;
    
    if (self.isRoot) {
        tempButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete" 
                                                      style:UIBarButtonItemStyleBordered 
                                                     target:self 
                                                     action:@selector(deleteSelectedItems)];
        tempButton.tintColor = [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:1.0];
        tempButton.width = 80.0;
        [toolbarButtons addObject:tempButton];
        self.deleteButton = tempButton;
    }
        
    self.toolbarItems = [NSArray arrayWithArray:toolbarButtons];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self
                                                                                           action:@selector(toggleEditMode)];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;

    if (self.isRoot) {
        // Add a version number header
        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 
                                                             0 - self.view.frame.size.height, 
                                                             self.view.frame.size.width, 
                                                             self.view.frame.size.height)];
        v.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        v.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.view insertSubview:v belowSubview:self.tableView];
                     
        NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
        NSString *versionStr = [NSString stringWithFormat:@"Version %@ (%@)", 
                                [appInfo objectForKey:@"CFBundleShortVersionString"], 
                                [appInfo objectForKey:@"CFBundleVersion"]];
        UILabel * l = [[UILabel alloc] initWithFrame:CGRectMake(0, 
                                                                v.frame.size.height - self.tableView.rowHeight, 
                                                                v.frame.size.width, 
                                                                self.tableView.rowHeight)];
        l.text = versionStr;
        l.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        l.textAlignment = UITextAlignmentCenter;
        l.font = [UIFont boldSystemFontOfSize:16.0];
        l.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        l.backgroundColor = [UIColor clearColor];
        l.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.7];
        l.shadowOffset = CGSizeMake(0, 1);
        [v addSubview:l];
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

#pragma mark - UITableViewController methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (editing) {
        for (UIBarButtonItem *button in self.toolbarItems) {
            button.enabled = NO;
        }
    }
    [self.navigationController setToolbarHidden:!editing animated:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.container.fileWrappers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    GSFileWrapper *wrapper = [self.container fileWrapperAtIndex:indexPath.row];
    cell.textLabel.text = wrapper.displayName;
    
    if (wrapper.isRegularFile) {
        if (self.isRoot) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Added on %@", [self.subtitleDateFormatter stringFromDate:wrapper.attributes.fileModificationDate]];
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
    return indexPath.section == 0;
}

//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{    
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        // Delete the row from the data source
//        NSError *error = nil;
//        [self.container removeItemAtIndex:indexPath.row error:&error];
//        if (error) {
//            NSLog(@"Error on deleting object at row %u of %@: %@, %@", indexPath.row, self, error, error.userInfo);
//        } else {
//            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//        }
//    }   
//}
//
#pragma mark - Table view delegate

- (void)updateToolbarButtons 
{
    NSUInteger numSelected = [[self.tableView indexPathsForSelectedRows] count];
    
    if (numSelected) {
        self.deleteButton.title = [NSString stringWithFormat:@"Delete (%u)", numSelected];
        self.shareButton.title = [NSString stringWithFormat:@"Share (%u)", numSelected];
    } else {
        self.deleteButton.title = @"Delete";
        self.shareButton.title = @"Share";
    }
    
    for (UIBarButtonItem *button in self.toolbarItems) {
        button.enabled = numSelected > 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56.0;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing) {
        [self updateToolbarButtons];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing) {
        [self updateToolbarButtons];
    } else {
        GSFileWrapper *wrapper = [self.container fileWrapperAtIndex:indexPath.row];
        
        if (wrapper.isImageFile) {
            GSImagePreviewController *vc = [[GSImagePreviewController alloc] init];
            NSArray *imageFileWrappers = self.container.imageFileWrappers;
            NSUInteger initialIndex = [imageFileWrappers indexOfObject:wrapper];
            
            assert(initialIndex != NSNotFound);
            
            vc.imageFileWrappers = imageFileWrappers;
            vc.initialIndex = initialIndex;
            
            [[UIApplication sharedApplication] setStatusBarStyle:UIBarStyleBlackTranslucent];
            self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
            
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
            mailComposer.mailComposeDelegate = self;
            
            for (NSIndexPath *indexPath in [self.tableView indexPathsForSelectedRows]) {
                GSFileWrapper *wrapper = [self.container fileWrapperAtIndex:indexPath.row];
                CFStringRef utiStringRef = (__bridge CFStringRef)wrapper.documentInteractionController.UTI;
                
                // UTTypeCopy... retains its return value (contains the word "copy"), so we
                // need to balance this with a release. We either do that manually by keeping
                // a pointer to the CFStringRef and then calling CFRelease() on it, or we 
                // transfer responsility for memory management to ARC by using 
                // __bridge_transfer and let ARC sort it out.
                // See http://www.mikeash.com/pyblog/friday-qa-2011-09-30-automatic-reference-counting.html
                // for more on this.
                NSString *mimeType = (__bridge_transfer NSString*)UTTypeCopyPreferredTagWithClass(utiStringRef,
                                                                                                  kUTTagClassMIMEType);
                if (!mimeType) {
                    mimeType = @"application/octet-stream";
                }
                
                NSLog(@"Attaching %@ to email with MIME type %@", wrapper.name, mimeType);
                
                [mailComposer addAttachmentData:[NSData dataWithContentsOfURL:wrapper.url]
                                       mimeType:mimeType
                                       fileName:wrapper.name];
            }
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

- (void)toggleEditMode
{
    [self setEditing:!self.editing animated:YES];
}

- (void)shareSelectedItems
{
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Share files"
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:@"Email", nil];
    [as showInView:self.view];
}

- (void)deleteSelectedItems
{
    
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
