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

@interface GSFileContainerListViewController : UITableViewController <UIDocumentInteractionControllerDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
    NSDateFormatter * _subtitleDateFormatter;
    BOOL _isRoot;
}

- (id)initWithContainer:(GSFileWrapper*)container;

@property (nonatomic, retain) GSFileWrapper * container;
@property (readonly) NSDateFormatter * subtitleDateFormatter;
@property (nonatomic) BOOL isRoot;

@end
