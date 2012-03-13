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
#import "GSUnrecognisedFileTypeViewController.h"

enum {
    GSFileContainerListViewActionSheetShare = 1,
    GSFileContainerListViewActionSheetDelete,
    GSFileContainerListViewActionSaveImages,
};

@interface GSFileContainerListViewController()

@property (nonatomic, retain) UIBarButtonItem *editButton;
@property (nonatomic, retain) UIBarButtonItem *doneButton;
@property (nonatomic, retain) NSArray *selectedImageFileWrappers;

- (void)handleContentsReloaded:(NSNotification*)notification;
- (void)handleContentsFailedToReload:(NSNotification*)notification;

- (void)shareSelectedItems;
- (void)deleteSelectedItems;
- (void)saveSelectedImages;
- (void)updateToolbarButtons;

@end

@implementation GSFileContainerListViewController

@synthesize container=_container;
@synthesize isRoot=isRoot;
@synthesize shareButton=_shareButton;
@synthesize deleteButton=_deleteButton;
@synthesize saveImagesButton=_saveImagesButton;
@synthesize selectedImageFileWrappers=_selectedImageFileWrappers;

@synthesize editButton=_editButton;
@synthesize doneButton=_doneButton;

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
    
    if (self.isRoot) {
        UIImageView *titleImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-bar-title.png"]];
        titleImage.contentMode = UIViewContentModeScaleAspectFit;
        self.navigationItem.titleView = titleImage;
    }
    
    
    
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
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.7 green:0.0 blue:0.0 alpha:1.0];
    self.navigationController.toolbar.tintColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    
    [self.navigationController setToolbarHidden:YES animated:animated];

    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.container.visited = YES;
}

#pragma mark - UI orientation methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.isRoot) {
        if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
            self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-bar-title.png"]];
        } else {
            self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-bar-title-landscape.png"]];
        }
    }
}

#pragma mark - Utility methods

- (void)updateToolbarButtons 
{
    NSUInteger numSelected = [[self.tableView indexPathsForSelectedRows] count];
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:self.container.fileWrappers.count];
    for (NSIndexPath *ip in [self.tableView indexPathsForSelectedRows]) {
        GSFileWrapper *wrapper = [self.container.fileWrappers objectAtIndex:ip.row];
        if (wrapper.isImageFile) {
            [tempArray addObject:wrapper];
        }
    }
    
    self.selectedImageFileWrappers = [NSArray arrayWithArray:tempArray];
    
    if (numSelected) {
        self.deleteButton.title = [NSString stringWithFormat:@"Delete (%u)", numSelected];
        self.shareButton.title = [NSString stringWithFormat:@"Share (%u)", numSelected];
        self.deleteButton.enabled = YES;
        self.shareButton.enabled = YES;
    } else {
        self.deleteButton.title = @"Delete";
        self.shareButton.title = @"Share";
        self.deleteButton.enabled = NO;
        self.shareButton.enabled = NO;
    }
    
    if (self.selectedImageFileWrappers.count) {
        self.saveImagesButton.title = [NSString stringWithFormat:@"Save Images (%u)", numSelected];
        self.saveImagesButton.enabled = YES;
    } else {
        self.saveImagesButton.title = @"Save Images";
        self.saveImagesButton.enabled = NO;
    }
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
    // Set allowsMultipleSelectionDuringEditing to YES only while
    // editing. This gives us the golden combination of swipe-to-delete
    // while out of edit mode and multiple selections while in it.
    self.tableView.allowsMultipleSelectionDuringEditing = editing;
    
    [super setEditing:editing animated:animated];
    
    if (editing) {
        [TestFlight passCheckpoint:@"Entered edit mode"];
        for (UIBarButtonItem *button in self.toolbarItems) {
            button.enabled = NO;
        }
        self.navigationItem.rightBarButtonItem = self.doneButton;
    } else {
        self.navigationItem.rightBarButtonItem = self.editButton;
        self.selectedImageFileWrappers = nil;
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
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = wrapper.icon;
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Only allow swipe-to-delete in the root view
    return self.isRoot ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    GSFileWrapper *fileWrapper = [self.container.fileWrappers objectAtIndex:indexPath.row];
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
    } else {
        GSFileWrapper *wrapper = [self.container fileWrapperAtIndex:indexPath.row];
        
        if (wrapper.isImageFile) {
            GSImagePreviewController *vc = [[GSImagePreviewController alloc] init];
            NSArray *imageFileWrappers = self.container.imageFileWrappers;
            NSUInteger initialIndex = [imageFileWrappers indexOfObject:wrapper];
            
            vc.imageFileWrappers = imageFileWrappers;
            vc.initialIndex = initialIndex;
            
            [self.navigationController pushViewController:vc animated:YES];
        } else if (wrapper.isContainer) {
            GSFileContainerListViewController *vc = [[GSFileContainerListViewController alloc] initWithContainer:wrapper];
            vc.tableView.delegate = vc;
            [self.navigationController pushViewController:vc animated:YES];
        } else if (wrapper.documentInteractionController && [QLPreviewController canPreviewItem:wrapper.url]) {
            wrapper.documentInteractionController.delegate = self;
            [wrapper.documentInteractionController presentPreviewAnimated:YES];
        } else {
            GSUnrecognisedFileTypeViewController *vc = [[GSUnrecognisedFileTypeViewController alloc] initWithFileWrapper:wrapper];
            [self.navigationController pushViewController:vc animated:YES];
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
                [self setEditing:NO animated:YES];
            } else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                             message:@"You can't send mail on this device - do you need to set up an email account?"
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

            [self setEditing:NO animated:YES];
        }
    } else if (actionSheet.tag == GSFileContainerListViewActionSaveImages) {
        if (buttonIndex == actionSheet.firstOtherButtonIndex) {
            for (GSFileWrapper *wrapper in self.selectedImageFileWrappers) {
                UIImage *image = [UIImage imageWithContentsOfFile:wrapper.url.path];
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            }
        }
        [self setEditing:NO animated:YES];
    }
}

#pragma mark - UI event handlers

- (void)toggleEditMode
{
    [self setEditing:!self.editing animated:YES];
}

- (void)saveSelectedImages
{
    NSString *title;
    if (self.selectedImageFileWrappers.count == 1) {
        GSFileWrapper *imageFileWrapper = [self.selectedImageFileWrappers objectAtIndex:0];
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
        GSFileWrapper *fileWrapper = [self.container.fileWrappers objectAtIndex:index];
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
        GSFileWrapper *fileWrapper = [self.container.fileWrappers objectAtIndex:index];
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
