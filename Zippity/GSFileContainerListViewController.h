//
//  GSFileListViewController.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GSFileWrapper.h"
#import <MessageUI/MessageUI.h>

@interface GSFileContainerListViewController : UITableViewController <UIDocumentInteractionControllerDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

- (id)initWithContainer:(GSFileWrapper*)container;
//- (id)initWithContainer:(GSFileWrapper*)container andSortOrder:(GSFileContainerSortOrder)sortOrder;

//@property (nonatomic) GSFileContainerSortOrder sortOrder;
@property (nonatomic, retain) GSFileWrapper * container;

@end
