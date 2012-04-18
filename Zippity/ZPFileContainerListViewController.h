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
@property (nonatomic, weak) UIActionSheet *currentActionSheet;

@end
