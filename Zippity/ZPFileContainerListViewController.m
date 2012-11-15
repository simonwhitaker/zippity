//
//  GSFileListViewController.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

/*
 Common localised strings. If a string is localised more than once, put the
 appropriate translation macro here for genstrings to find, then use
 [[NSBundle mainBundle] localizedStringForKey:] in the code.
 
 NSLocalizedString("Cancel",        "The text for a button that will cancel an action when tapped")
 NSLocalizedString("Delete",        "The text for a button that will delete files when tapped")
 NSLocalizedString("Email",         "The text for a button that will start composing an email when tapped")
 NSLocalizedString("OK",            "The text for a button that confirms a message has been received when tapped")
 NSLocalizedString("Error",         "The title for a message box shown when an error occurs")
 NSLocalizedString("Share",         "The text for a button that will share files when tapped, for example by email")
 NSLocalizedString("Save Images",   "The text for a button that will save image files to the camera roll when tapped")
 */

#import <MobileCoreServices/MobileCoreServices.h>
#import <QuartzCore/QuartzCore.h>
#import "ZPAppDelegate.h"
#import "ZPFileContainerListViewController.h"
#import "ZPPreviewController.h"
#import "ZPUnrecognisedFileTypeViewController.h"
#import "ZPEncodingPickerViewController.h"
#import <DropboxSDK/DropboxSDK.h>
#import "ZPDropboxDestinationSelectionViewController.h"

// ZPArchive.h for the error codes
#import "ZPArchive.h" 

enum {
    GSFileContainerListViewActionSheetShare = 1,
    GSFileContainerListViewActionSheetDelete,
    GSFileContainerListViewActionSheetSaveImages,
};

@interface UIBarItem(ZPAdditions)

- (void)updateWithLabel:(NSString*)label andCount:(NSUInteger)count;

@end

@implementation UIBarItem(ZPAdditions)

- (void)updateWithLabel:(NSString *)label andCount:(NSUInteger)count
{
    if (count > 99) {
        self.title = [NSString stringWithFormat:@"%@ (99+)", label];
    } else if (count) {
        self.title = [NSString stringWithFormat:@"%@ (%u)", label, count];
    } else {
        self.title = label;
    }
    
    self.enabled = count > 0;
}

@end

@interface ZPFileContainerListViewController() <ZPDropboxDestinationSelectionViewControllerDelegate>

@property (nonatomic, retain) UIBarButtonItem *editButton;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, retain) NSArray *selectedImageFileWrappers;

- (void)handleContentsReloaded:(NSNotification*)notification;
- (void)handleContentsFailedToReload:(NSNotification*)notification;
- (void)handleApplicationDidBecomeActiveNotification:(NSNotification*)notification;

- (void)showInfoView:(id)sender;
- (void)shareSelectedItems:(id)sender;
- (void)deleteSelectedItems:(id)sender;
- (void)saveSelectedImages:(id)sender;
- (void)updateToolbarButtons;
- (void)updateUIForOrientation:(UIInterfaceOrientation)orientation;
- (void)showDropboxDestinationSelectionView:(id)sender;

// Prior to iOS 5.1, split view controller popovers shown in
// standard UIPopoverController views. From iOS 5.1 onwards they're
// shown as panels that slide in from the left. If we're showing an
// "old-style" popover we need to make sure we don't apply
// styling to the navigation controller, otherwise it messes up
// the navigation bar.
- (void)applyNavigationBarStylingForOrientation:(UIInterfaceOrientation)interfaceOrientation;

@end

@implementation ZPFileContainerListViewController

@synthesize container = _container;
@synthesize isRoot = isRoot;
@synthesize shareButton = _shareButton;
@synthesize deleteButton = _deleteButton;
@synthesize saveImagesButton = _saveImagesButton;
@synthesize selectedImageFileWrappers = _selectedImageFileWrappers;
@synthesize previewControllerFileWrapperIndex = _previewControllerFileWrapperIndex;

@synthesize editButton = _editButton;
@synthesize doneButton = _doneButton;
@synthesize selectedLeafNodeIndexPath = _selectedIndexPath;
@synthesize currentActionSheet = _currentActionSheet;

- (id)initWithContainer:(ZPFileWrapper*)container
{    
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _container = container;
        
        self.isRoot = NO;
        self.wantsFullScreenLayout = NO;
        self.title = self.container.name;

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
    
    [self updateUIForOrientation:self.interfaceOrientation];
    
    
    NSMutableArray * toolbarButtons = [NSMutableArray array];
    UIBarButtonItem * tempButton;
    tempButton = [[UIBarButtonItem alloc] initWithTitle:[[NSBundle mainBundle] localizedStringForKey:@"Share" value:nil table:nil]
                                                  style:UIBarButtonItemStyleBordered
                                                 target:self
                                                 action:@selector(shareSelectedItems:)];
    [toolbarButtons addObject:tempButton];
    self.shareButton = tempButton;
    
    if (self.isRoot) {
        tempButton = [[UIBarButtonItem alloc] initWithTitle:[[NSBundle mainBundle] localizedStringForKey:@"Delete" value:nil table:nil]
                                                      style:UIBarButtonItemStyleBordered 
                                                     target:self 
                                                     action:@selector(deleteSelectedItems:)];
        tempButton.tintColor = [UIColor colorWithRed:0.7 green:0.0 blue:0.0 alpha:1.0];
        [toolbarButtons addObject:tempButton];
        self.deleteButton = tempButton;
    } else {
        tempButton = [[UIBarButtonItem alloc] initWithTitle:[[NSBundle mainBundle] localizedStringForKey:@"Save Images" value:nil table:nil]
                                                      style:UIBarButtonItemStyleBordered
                                                     target:self
                                                     action:@selector(saveSelectedImages:)];
        [toolbarButtons addObject:tempButton];
        self.saveImagesButton = tempButton;
    }
        
    self.toolbarItems = [NSArray arrayWithArray:toolbarButtons];

    self.editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                    target:self
                                                                    action:@selector(toggleEditMode)];
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                    target:self
                                                                    action:@selector(toggleEditMode)];
    
    self.navigationItem.rightBarButtonItem = self.editButton;
    
    if (self.isRoot) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info.png"]
                                                                   landscapeImagePhone:[UIImage imageNamed:@"info.png"]
                                                                                 style:UIBarButtonItemStyleBordered
                                                                                target:self
                                                                                action:@selector(showInfoView:)];
        self.navigationItem.leftBarButtonItem.accessibilityLabel = NSLocalizedString(@"About Zippity", 
                                                                                     @"Accessibility label for the About button on the Zippity home view");
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:animated];

    [self updateUIForOrientation:self.interfaceOrientation];
    self.navigationController.toolbar.tintColor = [UIColor colorWithWhite:0.1 alpha:1.0];

    // On iPad in portrait mode, the current selection will be deselected when
    // the popover goes out of view. We want it to remain selected, as it does
    // in Mail.app.
    if (isIpad && self.selectedLeafNodeIndexPath) {
        [self.tableView selectRowAtIndexPath:self.selectedLeafNodeIndexPath
                                    animated:NO 
                              scrollPosition:UITableViewScrollPositionNone];
    }
    
    if (self.isRoot) {
        [self.container reloadContainerContents];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.container.containerStatus != ZPFileWrapperContainerStatusReady) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleContentsReloaded:)
                                                     name:ZPFileWrapperContainerDidReloadContents
                                                   object:self.container];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleContentsFailedToReload:)
                                                     name:ZPFileWrapperContainerDidFailToReloadContents
                                                   object:self.container];
    }
    
    [self.tableView reloadData];

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationDidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.tableView.editing) {
        [self toggleEditMode];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIApplicationDidBecomeActiveNotification 
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ZPFileWrapperContainerDidReloadContents
                                                  object:self.container];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ZPFileWrapperContainerDidFailToReloadContents
                                                  object:self.container];

    
    [super viewWillDisappear:animated];
}

- (void)applyNavigationBarStylingForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(interfaceOrientation);
    
    // Check whether UISplitViewController instances support pressentsWithGesture - new in iOS 5.1
    BOOL isUsingOldStylePopover = ![UISplitViewController instancesRespondToSelector:@selector(presentsWithGesture)];

    if (isIpad && isPortrait && isUsingOldStylePopover) {
        [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.tintColor = nil;
        if (self.isRoot) {
            self.navigationItem.titleView = nil;
        }
    } else {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav-bar-background.png"] forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav-bar-background-landscape.png"] forBarMetrics:UIBarMetricsLandscapePhone];
        self.navigationController.navigationBar.tintColor = kZippityRed;

        if (self.isRoot) {
            if (isIpad || UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
                self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-bar-title.png"]];
            } else {
                self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-bar-title-landscape.png"]];
            }
        }
    }
}

#pragma mark - UI orientation methods

- (void)updateUIForOrientation:(UIInterfaceOrientation)orientation
{
    [self applyNavigationBarStylingForOrientation:orientation];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (isIpad) {
        return YES;
    }
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self updateUIForOrientation:toInterfaceOrientation];
}

#pragma mark - Utility methods

- (void)updateToolbarButtons 
{
    NSUInteger numSelected = [[self.tableView indexPathsForSelectedRows] count];
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:self.container.fileWrappers.count];
    for (NSIndexPath *ip in [self.tableView indexPathsForSelectedRows]) {
        ZPFileWrapper *wrapper = [self.container.fileWrappers objectAtIndex:ip.row];
        if (wrapper.isImageFile) {
            [tempArray addObject:wrapper];
        }
    }
    
    self.selectedImageFileWrappers = [NSArray arrayWithArray:tempArray];
    
    [self.deleteButton updateWithLabel:[[NSBundle mainBundle] localizedStringForKey:@"Delete" value:nil table:nil] andCount:numSelected];
    [self.shareButton updateWithLabel:[[NSBundle mainBundle] localizedStringForKey:@"Share" value:nil table:nil] andCount:numSelected];
    [self.saveImagesButton updateWithLabel:[[NSBundle mainBundle] localizedStringForKey:@"Save Images" value:nil table:nil] andCount:[self.selectedImageFileWrappers count]];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.container.containerStatus == ZPFileWrapperContainerStatusReady) {
        return self.container.fileWrappers.count;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        CGFloat maxTableWidth = isIpad ? 320.0 : 480.0;
        
        // Set custom selected cell background
        CGRect cellFrame = CGRectMake(0, 0, maxTableWidth, [self tableView:tableView heightForRowAtIndexPath:indexPath]);
        UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:cellFrame];
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = selectedBackgroundView.frame;
        gradient.colors = [NSArray arrayWithObjects:
                           (id)[[UIColor colorWithWhite:0.6 alpha:1.0] CGColor], 
                           (id)[[UIColor colorWithWhite:0.35 alpha:1.0] CGColor], 
                           nil];
        [selectedBackgroundView.layer addSublayer:gradient];
        
        cell.selectedBackgroundView = selectedBackgroundView;
        
        UIView *multipleSelectionBackgroundView = [[UIView alloc] initWithFrame:cellFrame];
        multipleSelectionBackgroundView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        cell.multipleSelectionBackgroundView = multipleSelectionBackgroundView;

    }

    if (self.container.containerStatus == ZPFileWrapperContainerStatusReady) {
        ZPFileWrapper *wrapper = [self.container fileWrapperAtIndex:indexPath.row];
        cell.textLabel.text = wrapper.displayName;
        cell.textLabel.accessibilityLabel = wrapper.name;
        if (wrapper.isDirectory) {
            cell.textLabel.accessibilityLabel = [cell.textLabel.accessibilityLabel stringByAppendingString:@", folder"];
        }
        
        if (wrapper.isRegularFile) {
            if (self.isRoot) {
                NSString *formatString = NSLocalizedString(@"Added on %@", @"Subtitle for table cells in the home view. %@ is replaced with the date the file was added.");
                cell.detailTextLabel.text = [NSString stringWithFormat:formatString, [self.subtitleDateFormatter stringFromDate:wrapper.attributes.fileModificationDate]];
            } else {
                NSString *formatString = NSLocalizedString(@"%@, last modified on %@", @"Subtitle for a table cell showing a specific file from within a zip file. The placeholders are %1$@: filename, %2$@: file's last modified date.");
                cell.detailTextLabel.text = [NSString stringWithFormat:formatString, wrapper.humanFileSize, [self.subtitleDateFormatter stringFromDate:wrapper.attributes.fileModificationDate]];
            }
        }
        
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        if (isIpad) {
            // For icon images derived from document icons, we need
            // to size them down on iPad.
            UIImage *rawIcon = wrapper.icon;
            UIImage *resizedIcon = rawIcon;
            
            if (rawIcon.size.width > 32.0) {
                CGFloat newWidth = rawIcon.size.width / 2;
                CGFloat newHeight = rawIcon.size.height / 2;
                
                UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight), NO, rawIcon.scale);
                [rawIcon drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
                resizedIcon = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
            }
            cell.imageView.image = resizedIcon;
        } else {
            cell.imageView.image = wrapper.icon;
        }
    } else {
        cell.textLabel.text = NSLocalizedString(@"Unpacking contents...", @"Short message shown while unpacking a zip file");
        UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        cell.accessoryView = aiv;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [aiv startAnimating];
    }

    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Only allow swipe-to-delete in the root view
    return self.isRoot ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZPFileWrapper *fileWrapper = [self.container.fileWrappers objectAtIndex:indexPath.row];
    return !fileWrapper.isDirectory;
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

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing) {
        [self updateToolbarButtons];
    } else {
        self.selectedLeafNodeIndexPath = nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.isEditing) {
        if (![self tableView:tableView canEditRowAtIndexPath:indexPath]) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
        [self updateToolbarButtons];
    } else if (self.container.containerStatus == ZPFileWrapperContainerStatusReady) {
        ZPFileWrapper *wrapper = [self.container fileWrapperAtIndex:indexPath.row];
        
        if (wrapper.isContainer) {
            ZPFileContainerListViewController *vc = [[ZPFileContainerListViewController alloc] initWithContainer:wrapper];
            vc.tableView.delegate = vc;
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            self.selectedLeafNodeIndexPath = indexPath;

            UIViewController *vc = nil;
            
            if (wrapper.isImageFile) {
                ZPImagePreviewController *ipc = [[ZPImagePreviewController alloc] init];
                ipc.delegate = self;
                NSArray *imageFileWrappers = self.container.imageFileWrappers;
                NSUInteger initialIndex = [imageFileWrappers indexOfObject:wrapper];
                
                ipc.imageFileWrappers = imageFileWrappers;
                ipc.initialIndex = initialIndex;
                
                vc = ipc;
            } else if (wrapper.documentInteractionController && [ZPPreviewController canPreviewItem:wrapper.url]) {
                if (isIpad) {
                    self.previewControllerFileWrapperIndex = indexPath.row;
                    ZPPreviewController *pc = [[ZPPreviewController alloc] init];
                    pc.dataSource = self;
                    vc = pc;
                } else {
                    wrapper.documentInteractionController.delegate = self;
                    [wrapper.documentInteractionController presentPreviewAnimated:YES];
                }
            } else {
                vc = [[ZPUnrecognisedFileTypeViewController alloc] initWithFileWrapper:wrapper];
            }
            
            if (vc) {
                if (isIpad) {
                    [(ZPAppDelegate*)[[UIApplication sharedApplication] delegate] setDetailViewController:vc];
                } else {
                    [self.navigationController pushViewController:vc animated:YES];
                }
            }
            [(ZPAppDelegate*)[[UIApplication sharedApplication] delegate] dismissMasterPopover];
        }
    }
}

#pragma mark - ZPAboutViewController delegate

- (void)aboutViewControllerShouldDismiss:(ZPAboutViewController *)aboutViewController
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - ZPImagePreviewController delegate

- (void)imagePreviewControllerDidShowImageForFileWrapper:(ZPFileWrapper *)fileWrapper
{
    NSInteger index = [self.container.fileWrappers indexOfObject:fileWrapper];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath
                                    animated:YES 
                              scrollPosition:UITableViewScrollPositionMiddle];
        self.selectedLeafNodeIndexPath = indexPath;
    }
}

#pragma mark - QLPreviewController data source

- (NSInteger) numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    // We're not supporting paging through previews, so we'll always just return
    // a preview controller with a single item. We'll use self.previewControllerFileWrapperIndex
    // to track the index of the file wrapper we need to show.
    return 1;
}

- (id<QLPreviewItem>) previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    ZPFileWrapper *wrapper = [self.container fileWrapperAtIndex:self.previewControllerFileWrapperIndex];
    return wrapper.url;
}

#pragma mark - UIDocumentInteractionController delegate

- (UIViewController*)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self.navigationController;
}

#pragma mark - MFMailComposeViewController delegate methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultSent) {
        [TestFlight passCheckpoint:@"Emailed some files"];
    }
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIActionSheet delegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.currentActionSheet = nil;

    if (actionSheet.tag == GSFileContainerListViewActionSheetShare) {
        NSString *emailLabel = [[NSBundle mainBundle] localizedStringForKey:@"Email" value:nil table:nil];
        NSString *dropboxLabel = [[NSBundle mainBundle] localizedStringForKey:@"Dropbox" value:nil table:nil];
        
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:emailLabel]) {
            if ([MFMailComposeViewController canSendMail]) {
                MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
                mailComposer.mailComposeDelegate = self;
                
                for (NSIndexPath *indexPath in [self.tableView indexPathsForSelectedRows]) {
                    ZPFileWrapper *wrapper = [self.container fileWrapperAtIndex:indexPath.row];
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
                                        
                    [mailComposer addAttachmentData:[NSData dataWithContentsOfURL:wrapper.url]
                                           mimeType:mimeType
                                           fileName:wrapper.name];
                }
                [self presentModalViewController:mailComposer animated:YES];
                if (self.tableView.editing) {
                    [self toggleEditMode];
                }
            } else {
                NSString *message = NSLocalizedString(@"You don't have an email account configured. You can set one up in the main Settings app.", 
                                                      @"Message shown to a user when they try to email a file but have not set up an email account on their iPhone.");

                UIAlertView *av = [[UIAlertView alloc] initWithTitle:[[NSBundle mainBundle] localizedStringForKey:@"Error" value:nil table:nil]
                                                             message:message
                                                            delegate:nil
                                                   cancelButtonTitle:[[NSBundle mainBundle] localizedStringForKey:@"OK" value:nil table:nil]
                                                   otherButtonTitles:nil];
                [av show];
            }
        }
        else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:dropboxLabel]) {
            /* Handle Dropbox uploads */
            self.selectedIndexPathsForDropboxUpload = [self.tableView indexPathsForSelectedRows];
            if (![[DBSession sharedSession] isLinked]) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.selectedIndexPathsForDropboxUpload]
                                                          forKey:kZPDefaultsDropboxUploadSelection];
                [[NSUserDefaults standardUserDefaults] setObject:self.container.url.absoluteString forKey:kZPDefaultsDropboxUploadCurrentContainerPath];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [[DBSession sharedSession] linkFromController:self];
            } else {
                [self showDropboxDestinationSelectionView:nil];
            }
        }
    } else if (actionSheet.tag == GSFileContainerListViewActionSheetDelete) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            NSMutableArray * successfullyDeleted = [NSMutableArray array];
            NSMutableArray * failedToDelete = [NSMutableArray array];
            
            // First get the list of selected index paths and sort it in descending order.
            // If we don't do this then we'll cause problems if we want to delete, e.g., 
            // items at indices 3 and 4 of a 5-item list. After deleting list[3] the list
            // only has 4 elements remaining, so trying to delete list[4] will generate
            // an index-out-of-bounds exception.
            NSArray * sortedPathsDescending = [[self.tableView indexPathsForSelectedRows] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                NSInteger row1 = [(NSIndexPath*)obj1 row];
                NSInteger row2 = [(NSIndexPath*)obj2 row];
                
                if (row1 > row2) {
                    return NSOrderedAscending;
                } else if (row1 < row2) {
                    return NSOrderedDescending;
                }
                return NSOrderedSame;
            }];
            
            // Now delete the objects we need to delete in reverse index
            // order, highest index first.
            for (NSIndexPath *indexPath in sortedPathsDescending) {
                NSError *error = nil;
                BOOL removed = [self.container removeItemAtIndex:indexPath.row error:&error];
                if (!removed) {
                    NSLog(@"Error on deleting object at row %u of %@: %@, %@", indexPath.row, self, error, error.userInfo);
                    [failedToDelete addObject:indexPath];
                } else {
                    [successfullyDeleted addObject:indexPath];
                }
            }
            [self.tableView deleteRowsAtIndexPaths:successfullyDeleted
                                  withRowAnimation:UITableViewRowAnimationFade];
            
            // TODO: show error if failedToDelete.count isn't 0?
            
            [TestFlight passCheckpoint:@"Deleted some files"];

            if (self.tableView.editing) {
                [self toggleEditMode];
            }
        }
    } else if (actionSheet.tag == GSFileContainerListViewActionSheetSaveImages) {
        if (buttonIndex == actionSheet.firstOtherButtonIndex) {
            for (ZPFileWrapper *wrapper in self.selectedImageFileWrappers) {
                UIImage *image = [UIImage imageWithContentsOfFile:wrapper.url.path];
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            }
            if (self.tableView.editing) {
                [self toggleEditMode];
            }
        }
    }
}

#pragma mark - ZPDropboxDestinationSelection view controller delegate methods

- (void)dropboxDestinationSelectionViewController:(ZPDropboxDestinationSelectionViewController *)viewController
                         didSelectDestinationPath:(NSString *)destinationPath
{
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Uploading files to %@", destinationPath);
        for (NSIndexPath *indexPath in self.selectedIndexPathsForDropboxUpload) {
            ZPFileWrapper *wrapper = [self.container fileWrapperAtIndex:indexPath.row];
            [[ZPDropboxUploader sharedUploader] uploadFileWrapper:wrapper toPath:destinationPath];
        }
        [[ZPDropboxUploader sharedUploader] start];
        self.selectedIndexPathsForDropboxUpload = nil;
    }];
}

- (void)dropboxDestinationSelectionViewControllerDidCancel:(ZPDropboxDestinationSelectionViewController *)viewController
{
    NSLog(@"User cancelled Dropbox destination selection dialog. Nothing to do here.");
    self.selectedIndexPathsForDropboxUpload = nil;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UI event handlers

- (void)showDropboxDestinationSelectionView:(id)sender
{
    ZPDropboxDestinationSelectionViewController *vc = [[ZPDropboxDestinationSelectionViewController alloc] init];
    vc.delegate = self;
    vc.rootPath = @"/";
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:nc animated:YES completion:NULL];

    [TestFlight passCheckpoint:@"Showed Dropbox destination selection view"];
}

- (void)showInfoView:(id)sender
{
    NSString *nibName = isIpad ? @"ZPAboutViewController-iPad" : @"ZPAboutViewController";
    ZPAboutViewController *vc = [[ZPAboutViewController alloc] initWithNibName:nibName bundle:nil];
    vc.delegate = self;
    vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.navigationController presentModalViewController:vc animated:YES];
}

- (void)toggleEditMode
{
    BOOL editing = !self.tableView.editing;
    
    // Set allowsMultipleSelectionDuringEditing to YES only while
    // editing. This gives us the golden combination of swipe-to-delete
    // while out of edit mode and multiple selections while in it.
    self.tableView.allowsMultipleSelectionDuringEditing = editing;
    
    [self.tableView setEditing:editing animated:YES];
    
    if (editing) {
        self.selectedLeafNodeIndexPath = nil;
        [TestFlight passCheckpoint:@"Entered edit mode"];
        [self updateToolbarButtons];
        self.navigationItem.rightBarButtonItem = self.doneButton;
    } else {
        self.navigationItem.rightBarButtonItem = self.editButton;
        self.selectedImageFileWrappers = nil;
    }
    [self.navigationController setToolbarHidden:!editing animated:YES];
}

- (void)saveSelectedImages:(id)sender
{
    if (self.currentActionSheet) {
        BOOL wasShowing = self.currentActionSheet.tag == GSFileContainerListViewActionSheetSaveImages;
        [self.currentActionSheet dismissWithClickedButtonIndex:self.currentActionSheet.cancelButtonIndex animated:wasShowing];
        if (wasShowing) {
            return;
        }
    }
    
    NSString *title;
    if (self.selectedImageFileWrappers.count == 1) {
        ZPFileWrapper *imageFileWrapper = [self.selectedImageFileWrappers objectAtIndex:0];
        NSString * formatString = NSLocalizedString(@"Save %@", 
                                                    @"The title for a confirmation dialog shown when saving a file. %@ is replaced by the filename of the file.");
        title = [NSString stringWithFormat:formatString, imageFileWrapper.name];
    } else {
        NSString * formatString = NSLocalizedString(@"Save %u images", 
                                                    @"The title for a confirmation dialog shown when saving files. %u is replaced by the number of files being saved.");
        title = [NSString stringWithFormat:formatString, self.selectedImageFileWrappers.count];
    }
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:title
                                                    delegate:self
                                           cancelButtonTitle:[[NSBundle mainBundle] localizedStringForKey:@"Cancel" value:nil table:nil]
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:NSLocalizedString(@"Save to Photos", @"Button text for Save to Photos button in action sheet"), nil];
    as.tag = GSFileContainerListViewActionSheetSaveImages;

    if (isIpad && UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        // Presenting an alert view from a button in a popover on iPad running 
        // iOS 5.1 results in a crash - see http://stackoverflow.com/questions/9727917/
        // So we'll show the alert view from the window instead.
        [as showInView:self.view.window];
    } else {
        [as showFromBarButtonItem:sender animated:YES];
    }
    
    self.currentActionSheet = as;
}

- (void)shareSelectedItems:(id)sender
{
    if (self.currentActionSheet) {
        BOOL wasShowing = self.currentActionSheet.tag == GSFileContainerListViewActionSheetShare;
        [self.currentActionSheet dismissWithClickedButtonIndex:self.currentActionSheet.cancelButtonIndex animated:wasShowing];
        if (wasShowing) {
            return;
        }
    }

    NSString *title;
    if ([[self.tableView indexPathsForSelectedRows] count] == 1) {
        NSUInteger index = [[[self.tableView indexPathsForSelectedRows] objectAtIndex:0] row];
        ZPFileWrapper *fileWrapper = [self.container.fileWrappers objectAtIndex:index];
        NSString *formatString = NSLocalizedString(@"Share %@", 
                                                   @"The title for a confirmation dialog shown when sharing a file. %@ is replaced by the filename of a single selected file.");
        title = [NSString stringWithFormat:formatString, fileWrapper.name];
    } else {
        NSString *formatString = NSLocalizedString(@"Share %u files", 
                                                   @"The title for a confirmation dialog shown when sharing files. %u is replaced by the number of selected files.");
        title = [NSString stringWithFormat:formatString, [[self.tableView indexPathsForSelectedRows] count]];
    }
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:title
                                                    delegate:self
                                           cancelButtonTitle:[[NSBundle mainBundle] localizedStringForKey:@"Cancel" value:nil table:nil]
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:[[NSBundle mainBundle] localizedStringForKey:@"Email" value:nil table:nil],
                                                             [[NSBundle mainBundle] localizedStringForKey:@"Dropbox" value:nil table:nil],
                                                             nil];
    as.tag = GSFileContainerListViewActionSheetShare;
    
    if (isIpad && UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        // Presenting an alert view from a button in a popover on iPad running 
        // iOS 5.1 results in a crash - see http://stackoverflow.com/questions/9727917/
        // So we'll show the alert view from the window instead.
        [as showInView:self.view.window];
    } else {
        [as showFromBarButtonItem:sender animated:YES];
    }
    
    self.currentActionSheet = as;
}

- (void)deleteSelectedItems:(id)sender
{
    if (self.currentActionSheet) {
        BOOL wasShowing = self.currentActionSheet.tag == GSFileContainerListViewActionSheetDelete;
        [self.currentActionSheet dismissWithClickedButtonIndex:self.currentActionSheet.cancelButtonIndex animated:wasShowing];
        if (wasShowing) {
            return;
        }
    }

    NSString *title;
    if ([[self.tableView indexPathsForSelectedRows] count] == 1) {
        NSUInteger index = [[[self.tableView indexPathsForSelectedRows] objectAtIndex:0] row];
        ZPFileWrapper *fileWrapper = [self.container.fileWrappers objectAtIndex:index];
        NSString * formatString = NSLocalizedString(@"Delete %@", 
                                                    @"The title for a confirmation dialog shown when deleting a file. %@ is replaced by the filename of a single selected file.");
        title = [NSString stringWithFormat:formatString, fileWrapper.name];
    } else {
        NSString * formatString = NSLocalizedString(@"Delete %u files",
                                                    @"The title for a confirmation dialog shown when deleting files. %@ is replaced by the number of selected files.");
        title = [NSString stringWithFormat:formatString, [[self.tableView indexPathsForSelectedRows] count]];
    }
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:title
                                                    delegate:self
                                           cancelButtonTitle:[[NSBundle mainBundle] localizedStringForKey:@"Cancel" value:nil table:nil]
                                      destructiveButtonTitle:[[NSBundle mainBundle] localizedStringForKey:@"Delete" value:nil table:nil]
                                           otherButtonTitles:nil];
    as.tag = GSFileContainerListViewActionSheetDelete;
    
    if (isIpad && UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        // Presenting an alert view from a button in a popover on iPad running 
        // iOS 5.1 results in a crash - see http://stackoverflow.com/questions/9727917/
        // So we'll show the alert view from the window instead.
        [as showInView:self.view.window];
    } else {
        [as showFromBarButtonItem:sender animated:YES];
    }
    
    self.currentActionSheet = as;
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (!self.isRoot) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Notification handlers

- (void)handleContentsReloaded:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (void)handleContentsFailedToReload:(NSNotification *)notification
{
    NSError *error = [[notification userInfo] objectForKey:kErrorKey];
    NSString *errorMessage;
    

    if (error.domain == ZPFileWrapperErrorDomain && error.code == ZPFileWrapperErrorFailedToExtractArchive) {
        NSError * underlyingError = [[error userInfo] objectForKey:NSUnderlyingErrorKey];
        if (underlyingError && underlyingError.domain == kGSArchiveErrorDomain && underlyingError.code == GSArchiveEntryFilenameEncodingUnknownError) {
            NSData * samplePathCString = [[underlyingError userInfo] objectForKey:kGSArchiveEntryFilenameCStringAsNSData];
            ZPEncodingPickerViewController * vc = [[ZPEncodingPickerViewController alloc] initWithStyle:UITableViewStyleGrouped];
            vc.delegate = self;
            vc.sampleFilenameCString = samplePathCString;

            UINavigationController * nc = [[UINavigationController alloc] initWithRootViewController:vc];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            
            [self presentModalViewController:nc animated:YES];
            return;
        } else {
            errorMessage = NSLocalizedString(@"Zippity couldn't open that archive file. It might be corrupt.", 
                                             @"Error message to display when a zip file can't be opened.");
        }
    } else {
        errorMessage = NSLocalizedString(@"Zippity can't list the files in this folder.",
                                         @"Error message to display when the contents of a zip file can't be displayed for some unknown reason.");
    }

    // Show error to user
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:[[NSBundle mainBundle] localizedStringForKey:@"Error" value:nil table:nil]
                                                 message:errorMessage
                                                delegate:self
                                       cancelButtonTitle:nil
                                       otherButtonTitles:[[NSBundle mainBundle] localizedStringForKey:@"OK" value:nil table:nil], nil];
    [av show];
}

- (void)handleApplicationDidBecomeActiveNotification:(NSNotification *)notification
{
    [self.tableView reloadData];
        
    /* If we're reappearing after leaving the app to authenticate with Dropbox, pick up where we left off. */
    NSData *selectionForDropboxUploadData = [[NSUserDefaults standardUserDefaults] objectForKey:kZPDefaultsDropboxUploadSelection];
    NSString *dropboxUploadPreviousContainerPath = [[NSUserDefaults standardUserDefaults] objectForKey:kZPDefaultsDropboxUploadCurrentContainerPath];
    if (selectionForDropboxUploadData != nil && [dropboxUploadPreviousContainerPath isEqualToString:self.container.url.absoluteString]) {
        
        [TestFlight passCheckpoint:@"Opened app after authenticating with Dropbox"];

        NSArray *selectionForDropboxUpload = [NSKeyedUnarchiver unarchiveObjectWithData:selectionForDropboxUploadData];
        if (!self.tableView.isEditing) {
            [self toggleEditMode];
        }
        for (NSIndexPath *ip in selectionForDropboxUpload) {
            NSLog(@"Selecting row at indexPath %@", ip);
            [self.tableView selectRowAtIndexPath:ip animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self updateToolbarButtons];
        }
        /* Show the Dropbox destination selection dialog, but wait a short while first so that the user sees that their selection's still intact first. */
        [self performSelector:@selector(showDropboxDestinationSelectionView:) withObject:nil afterDelay:1.0];
    }
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kZPDefaultsDropboxUploadSelection];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kZPDefaultsDropboxUploadCurrentContainerPath];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewControllerShouldDismiss:(UIViewController *)viewController wasCancelled:(BOOL)wasCancelled
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (wasCancelled) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self.tableView reloadData];
        }
    }];
}

@end
