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

@interface ZPFileContainerListViewController : UITableViewController <
MFMailComposeViewControllerDelegate,
QLPreviewControllerDataSource,
UIDocumentInteractionControllerDelegate, 
UIActionSheetDelegate, 
UIAlertViewDelegate,
ZPAboutViewControllerDelegate
> {
    NSDateFormatter * _subtitleDateFormatter;
    BOOL _isRoot;
}

- (id)initWithContainer:(ZPFileWrapper*)container;

@property (nonatomic, retain) ZPFileWrapper * container;
@property (readonly) NSDateFormatter * subtitleDateFormatter;
@property (nonatomic) BOOL isRoot;
@property NSInteger previewControllerFileWrapperIndex;

@property (nonatomic, assign) UIBarButtonItem * shareButton;
@property (nonatomic, assign) UIBarButtonItem * deleteButton;
@property (nonatomic, assign) UIBarButtonItem * saveImagesButton;

@end
