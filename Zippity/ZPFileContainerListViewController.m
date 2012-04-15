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

#import "ZPFileContainerListViewController.h"
#import "ZPAppDelegate.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "ZPImagePreviewController.h"
#import "ZPUnrecognisedFileTypeViewController.h"
#import "ZPPreviewController.h"

enum {
    GSFileContainerListViewActionSheetShare = 1,
    GSFileContainerListViewActionSheetDelete,
    GSFileContainerListViewActionSaveImages,
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

@interface ZPFileContainerListViewController()

@property (nonatomic, retain) UIBarButtonItem *editButton;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, retain) NSArray *selectedImageFileWrappers;

- (void)handleContentsReloaded:(NSNotification*)notification;
- (void)handleContentsFailedToReload:(NSNotification*)notification;
- (void)handleApplicationDidBecomeActiveNotification:(NSNotification*)notification;

- (void)showInfoView:(id)sender;
- (void)shareSelectedItems;
- (void)deleteSelectedItems;
- (void)saveSelectedImages;
- (void)updateToolbarButtons;
- (void)updateUIForOrientation:(UIInterfaceOrientation)orientation;

@end

@implementation ZPFileContainerListViewController

@synthesize container = _container;
@synthesize isRoot = isRoot;
@synthesize shareButton = _shareButton;
@synthesize deleteButton = _deleteButton;
@synthesize saveImagesButton = _saveImagesButton;
@synthesize selectedImageFileWrappers = _selectedImageFileWrappers;
@synthesize previewControllerFileWrapperIndex = _previewControllerFileWrapperIndex;

@synthesize editButton=_editButton;
@synthesize doneButton=_doneButton;

- (id)initWithContainer:(ZPFileWrapper*)container
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
    
    [self updateUIForOrientation:self.interfaceOrientation];
    
    
    NSMutableArray * toolbarButtons = [NSMutableArray array];
    UIBarButtonItem * tempButton;
    tempButton = [[UIBarButtonItem alloc] initWithTitle:[[NSBundle mainBundle] localizedStringForKey:@"Share" value:nil table:nil]
                                                  style:UIBarButtonItemStyleBordered
                                                 target:self
                                                 action:@selector(shareSelectedItems)];
    [toolbarButtons addObject:tempButton];
    self.shareButton = tempButton;
    
    if (self.isRoot) {
        tempButton = [[UIBarButtonItem alloc] initWithTitle:[[NSBundle mainBundle] localizedStringForKey:@"Delete" value:nil table:nil]
                                                      style:UIBarButtonItemStyleBordered 
                                                     target:self 
                                                     action:@selector(deleteSelectedItems)];
        tempButton.tintColor = [UIColor colorWithRed:0.7 green:0.0 blue:0.0 alpha:1.0];
        [toolbarButtons addObject:tempButton];
        self.deleteButton = tempButton;
    } else {
        tempButton = [[UIBarButtonItem alloc] initWithTitle:[[NSBundle mainBundle] localizedStringForKey:@"Save Images" value:nil table:nil]
                                                      style:UIBarButtonItemStyleBordered
                                                     target:self
                                                     action:@selector(saveSelectedImages)];
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

    if (self.isInOldStylePopover) {
        [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.tintColor = nil;
    } else {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav-bar-background.png"] forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav-bar-background-landscape.png"] forBarMetrics:UIBarMetricsLandscapePhone];
        self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.68 green:0.17 blue:0.11 alpha:1.0];
    }
    self.navigationController.toolbar.tintColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
    
    [super viewWillDisappear:animated];
}

- (BOOL)isInOldStylePopover
{
    // YES if we're on an iPad, in portrait orientation and running iOS <= 5.0
    BOOL result = isIpad && UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    
    // Check whether UISplitViewController instances support pressentsWithGesture - new in iOS 5.1
    result = result && ![UISplitViewController instancesRespondToSelector:@selector(presentsWithGesture)];
    
    return result;
}

#pragma mark - UI orientation methods

- (void)updateUIForOrientation:(UIInterfaceOrientation)orientation
{
    if (self.isRoot) {
        if ([self isInOldStylePopover]) {
            self.navigationItem.titleView = nil;
        } else if (isIpad || UIInterfaceOrientationIsPortrait(orientation)) {
            self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-bar-title.png"]];
        } else {
            self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-bar-title-landscape.png"]];
        }
    }
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
            UIImage *rawIcon = wrapper.icon;
            UIImage *resizedIcon;
            UIGraphicsBeginImageContext(CGSizeMake(32, 32));
            [rawIcon drawInRect:CGRectMake(0, 0, 32, 32)];
            resizedIcon = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
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
            UIViewController *vc = nil;
            
            if (wrapper.isImageFile) {
                ZPImagePreviewController *ipc = [[ZPImagePreviewController alloc] init];
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
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)setContainer:(ZPFileWrapper*)container
{
    if (_container != container) {
        // Remove old notification observers
        if (_container) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:ZPFileWrapperContainerDidReloadContents
                                                          object:_container];
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:ZPFileWrapperContainerDidFailToReloadContents
                                                          object:_container];
        }
        
        // Switch container ivar to new container
        _container = container;

        // Set up new notification observers
        if (_container) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleContentsReloaded:)
                                                         name:ZPFileWrapperContainerDidReloadContents
                                                       object:_container];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleContentsFailedToReload:)
                                                         name:ZPFileWrapperContainerDidFailToReloadContents
                                                       object:_container];
            self.title = container.name;
        }
    }
}

#pragma mark - ZPAboutViewController delegate

- (void)aboutViewControllerShouldDismiss:(ZPAboutViewController *)aboutViewController
{
    [self dismissModalViewControllerAnimated:YES];
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
    if (actionSheet.tag == GSFileContainerListViewActionSheetShare) {
        NSString * emailLabel = [[NSBundle mainBundle] localizedStringForKey:@"Email" value:nil table:nil];
        
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
    } else if (actionSheet.tag == GSFileContainerListViewActionSheetDelete) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            NSMutableArray * successfullyDeleted = [NSMutableArray array];
            NSMutableArray * failedToDelete = [NSMutableArray array];
            
            for (NSIndexPath *indexPath in [self.tableView indexPathsForSelectedRows]) {
                NSError *error = nil;
                [self.container removeItemAtIndex:indexPath.row error:&error];
                if (error) {
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
    } else if (actionSheet.tag == GSFileContainerListViewActionSaveImages) {
        if (buttonIndex == actionSheet.firstOtherButtonIndex) {
            for (ZPFileWrapper *wrapper in self.selectedImageFileWrappers) {
                UIImage *image = [UIImage imageWithContentsOfFile:wrapper.url.path];
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            }
        }
        if (self.tableView.editing) {
            [self toggleEditMode];
        }
    }
}

#pragma mark - UI event handlers

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
        [TestFlight passCheckpoint:@"Entered edit mode"];
        [self updateToolbarButtons];
        self.navigationItem.rightBarButtonItem = self.doneButton;
    } else {
        self.navigationItem.rightBarButtonItem = self.editButton;
        self.selectedImageFileWrappers = nil;
    }
    [self.navigationController setToolbarHidden:!editing animated:YES];
}

- (void)saveSelectedImages
{
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
    as.tag = GSFileContainerListViewActionSaveImages;
    [as showFromToolbar:self.navigationController.toolbar];
}

- (void)shareSelectedItems
{
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
                                           otherButtonTitles:[[NSBundle mainBundle] localizedStringForKey:@"Email" value:nil table:nil], nil];
    as.tag = GSFileContainerListViewActionSheetShare;
    [as showFromToolbar:self.navigationController.toolbar];
}

- (void)deleteSelectedItems
{
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
    [as showFromToolbar:self.navigationController.toolbar];
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
        errorMessage = NSLocalizedString(@"Zippity couldn't open that archive file. It might be corrupt.", 
                                         @"Error message to display when a zip file can't be opened.");
    } else {
        errorMessage = NSLocalizedString(@"Zippity can't list the files in this folder.",
                                         @"Error message to display when the contents of a zip file can't be displayed for some unknown reason.");
    }

    // TODO: show error to user
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
}

@end
