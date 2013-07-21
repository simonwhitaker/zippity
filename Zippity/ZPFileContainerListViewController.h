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
#import "ZPFileWrapper.h"
#import "ZPImagePreviewController.h"
#import "GSDismissableViewControllerDelegate.h"
#import "GSDropboxUploader.h"

@interface ZPFileContainerListViewController : UITableViewController <
GSDismissableViewControllerDelegate,
MFMailComposeViewControllerDelegate,
QLPreviewControllerDataSource,
UIDocumentInteractionControllerDelegate, 
UIActionSheetDelegate, 
UIAlertViewDelegate,
ZPImagePreviewControllerDelegate
> {
    NSDateFormatter * _subtitleDateFormatter;
    BOOL _isRoot;
    ZPFileWrapper * _container;
}

- (id)initWithContainer:(ZPFileWrapper*)container;

@property (readonly) ZPFileWrapper * container;
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

@property (nonatomic, strong) NSArray *selectedIndexPathsForDropboxUpload;
@property (nonatomic, weak) UIActionSheet *currentActionSheet;

@end
