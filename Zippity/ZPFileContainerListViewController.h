//
//  GSFileListViewController.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <QuickLook/QuickLook.h>
#import <UIKit/UIKit.h>
#import "ZPAboutViewController.h"
#import "ZPFileWrapper.h"
#import "ZPImagePreviewController.h"

@interface ZPFileContainerListViewController : UITableViewController <
MFMailComposeViewControllerDelegate,
QLPreviewControllerDataSource,
UIDocumentInteractionControllerDelegate, 
UIActionSheetDelegate, 
UIAlertViewDelegate,
ZPAboutViewControllerDelegate,
ZPImagePreviewControllerDelegate
> {
    NSDateFormatter * _subtitleDateFormatter;
    BOOL _isRoot;
}

- (id)initWithContainer:(ZPFileWrapper*)container;

@property (nonatomic, retain) ZPFileWrapper * container;
@property (readonly) NSDateFormatter * subtitleDateFormatter;
@property (nonatomic) BOOL isRoot;
@property NSInteger previewControllerFileWrapperIndex;

@property (nonatomic, weak) UIBarButtonItem * shareButton;
@property (nonatomic, weak) UIBarButtonItem * deleteButton;
@property (nonatomic, weak) UIBarButtonItem * saveImagesButton;

// Keep track of the selected index path so that we can 
// highlight it when displaying the view, e.g. in a popover
// on iPad.
@property (nonatomic, strong) NSIndexPath * selectedLeafNodeIndexPath;

// Prior to iOS 5.1, split view controller popovers shown in
// standard UIPopoverController views. From iOS 5.1 onwards they're
// shown as panels that slide in from the left. If we're showing an
// "old-style" popover we need to make sure we don't apply
// styling to the navigation controller, otherwise it messes up
// the navigation bar.
@property (readonly) BOOL isInOldStylePopover;

@property (nonatomic, weak) UIActionSheet *currentActionSheet;

@end
