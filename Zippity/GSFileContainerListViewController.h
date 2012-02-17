//
//  GSFileListViewController.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GSFileContainer.h"

@interface GSFileContainerListViewController : UITableViewController <UIDocumentInteractionControllerDelegate>

@property (nonatomic, retain) id<GSFileContainer> container;

@end
