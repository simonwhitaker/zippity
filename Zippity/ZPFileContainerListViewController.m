//
//  GSFileListViewController.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPFileContainerListViewController.h"
#import "ZPAppDelegate.h"
#import <QuickLook/QuickLook.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ZPImagePreviewController.h"
#import "ZPUnrecognisedFileTypeViewController.h"

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

@synthesize container=_container;
@synthesize isRoot=isRoot;
@synthesize shareButton=_shareButton;
@synthesize deleteButton=_deleteButton;
@synthesize saveImagesButton=_saveImagesButton;
@synthesize selectedImageFileWrappers=_selectedImageFileWrappers;

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
        tempButton.tintColor = [UIColor colorWithRed:0.7 green:0.0 blue:0.0 alpha:1.0];
        tempButton.width = 80.0;
        [toolbarButtons addObject:tempButton];
        self.deleteButton = tempButton;
    } else {
        tempButton = [[UIBarButtonItem alloc] initWithTitle:@"Save Images"
                                                      style:UIBarButtonItemStyleBordered
                                                     target:self
                                                     action:@selector(saveSelectedImages)];
        tempButton.width = 120.0;
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
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info-button-icon.png"]
                                                                   landscapeImagePhone:[UIImage imageNamed:@"info-button-icon.png"]
                                                                                 style:UIBarButtonItemStyleBordered
                                                                                target:self
                                                                                action:@selector(showInfoView:)];
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
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:animated];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav-bar-background.png"] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav-bar-background-landscape.png"] forBarMetrics:UIBarMetricsLandscapePhone];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.7 green:0.0 blue:0.0 alpha:1.0];
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

#pragma mark - UI orientation methods

- (void)updateUIForOrientation:(UIInterfaceOrientation)orientation
{
    if (self.isRoot) {
        if (UIInterfaceOrientationIsPortrait(orientation)) {
            self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-bar-title.png"]];
        } else {
            self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-bar-title-landscape.png"]];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
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
    
    [self.deleteButton updateWithLabel:@"Delete" andCount:numSelected];
    [self.shareButton updateWithLabel:@"Share" andCount:numSelected];
    [self.saveImagesButton updateWithLabel:@"Save Images" andCount:[self.selectedImageFileWrappers count]];
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
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Added on %@", [self.subtitleDateFormatter stringFromDate:wrapper.attributes.fileModificationDate]];
            } else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, last modified on %@", wrapper.humanFileSize, [self.subtitleDateFormatter stringFromDate:wrapper.attributes.fileModificationDate]];
            }
        }
        
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.imageView.image = wrapper.icon;
    } else {
        cell.textLabel.text = @"Unpacking contents...";
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
        
        if (wrapper.isImageFile) {
            ZPImagePreviewController *vc = [[ZPImagePreviewController alloc] init];
            NSArray *imageFileWrappers = self.container.imageFileWrappers;
            NSUInteger initialIndex = [imageFileWrappers indexOfObject:wrapper];
            
            vc.imageFileWrappers = imageFileWrappers;
            vc.initialIndex = initialIndex;
            
            [self.navigationController pushViewController:vc animated:YES];
        } else if (wrapper.isContainer) {
            ZPFileContainerListViewController *vc = [[ZPFileContainerListViewController alloc] initWithContainer:wrapper];
            vc.tableView.delegate = vc;
            [self.navigationController pushViewController:vc animated:YES];
        } else if (wrapper.documentInteractionController && [QLPreviewController canPreviewItem:wrapper.url]) {
            wrapper.documentInteractionController.delegate = self;
            [wrapper.documentInteractionController presentPreviewAnimated:YES];
        } else {
            ZPUnrecognisedFileTypeViewController *vc = [[ZPUnrecognisedFileTypeViewController alloc] initWithFileWrapper:wrapper];
            [self.navigationController pushViewController:vc animated:YES];
        }
    } else {
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

#define kEmailButtonLabel @"Email"

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == GSFileContainerListViewActionSheetShare) {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(kEmailButtonLabel, nil)]) {
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
                    
                    NSLog(@"Attaching %@ to email with MIME type %@", wrapper.name, mimeType);
                    
                    [mailComposer addAttachmentData:[NSData dataWithContentsOfURL:wrapper.url]
                                           mimeType:mimeType
                                           fileName:wrapper.name];
                }
                [self presentModalViewController:mailComposer animated:YES];
                if (self.tableView.editing) {
                    [self toggleEditMode];
                }
            } else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                             message:@"You can't send mail on this device - maybe you need to set up an email account?"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
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
    ZPAboutViewController *vc = [[ZPAboutViewController alloc] initWithNibName:@"ZPAboutViewController" bundle:nil];
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
        title = [NSString stringWithFormat:@"Save %@", imageFileWrapper.name];
    } else {
        title = [NSString stringWithFormat:@"Save %u images", self.selectedImageFileWrappers.count];
    }
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:title
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:@"Save to Photos", nil];
    as.tag = GSFileContainerListViewActionSaveImages;
    [as showFromToolbar:self.navigationController.toolbar];
}

- (void)shareSelectedItems
{
    NSString *title;
    if ([[self.tableView indexPathsForSelectedRows] count] == 1) {
        NSUInteger index = [[[self.tableView indexPathsForSelectedRows] objectAtIndex:0] row];
        ZPFileWrapper *fileWrapper = [self.container.fileWrappers objectAtIndex:index];
        title = [NSString stringWithFormat:@"Share %@", fileWrapper.name];
    } else {
        title = [NSString stringWithFormat:@"Share %u files", [[self.tableView indexPathsForSelectedRows] count]];
    }
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:title
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:@"Email", nil];
    as.tag = GSFileContainerListViewActionSheetShare;
    [as showFromToolbar:self.navigationController.toolbar];
}

- (void)deleteSelectedItems
{
    NSString *title;
    if ([[self.tableView indexPathsForSelectedRows] count] == 1) {
        NSUInteger index = [[[self.tableView indexPathsForSelectedRows] objectAtIndex:0] row];
        ZPFileWrapper *fileWrapper = [self.container.fileWrappers objectAtIndex:index];
        title = [NSString stringWithFormat:@"Delete %@", fileWrapper.name];
    } else {
        title = [NSString stringWithFormat:@"Delete %u files", [[self.tableView indexPathsForSelectedRows] count]];
    }
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:title
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                      destructiveButtonTitle:@"Delete"
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
        errorMessage = @"Zippity couldn't open that archive file. It might be corrupt.";
    } else {
        errorMessage = @"Zippity can't list the files in this folder.";
    }

    // TODO: show error to user
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                 message:errorMessage
                                                delegate:self
                                       cancelButtonTitle:nil
                                       otherButtonTitles:@"OK", nil];
    [av show];
}

- (void)handleApplicationDidBecomeActiveNotification:(NSNotification *)notification
{
    [self.tableView reloadData];
}

@end
