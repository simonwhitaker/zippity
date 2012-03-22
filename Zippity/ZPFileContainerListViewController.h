//
//  GSFileListViewController.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZPFileWrapper.h"
#import <MessageUI/MessageUI.h>

@interface ZPFileContainerListViewController : UITableViewController <
UIDocumentInteractionControllerDelegate, 
UIActionSheetDelegate, 
UIAlertViewDelegate,
MFMailComposeViewControllerDelegate
> {
    NSDateFormatter * _subtitleDateFormatter;
    BOOL _isRoot;
}

- (id)initWithContainer:(ZPFileWrapper*)container;

@property (nonatomic, retain) ZPFileWrapper * container;
@property (readonly) NSDateFormatter * subtitleDateFormatter;
@property (nonatomic) BOOL isRoot;

@property (nonatomic, assign) UIBarButtonItem * shareButton;
@property (nonatomic, assign) UIBarButtonItem * deleteButton;
@property (nonatomic, assign) UIBarButtonItem * saveImagesButton;

@end
