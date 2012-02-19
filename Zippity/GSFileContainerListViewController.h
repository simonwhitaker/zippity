//
//  GSFileListViewController.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GSFileContainer.h"
#import "GSZipFile.h"

@interface GSFileContainerListViewController : UITableViewController <UIDocumentInteractionControllerDelegate>

- (id)initWithContainer:(id<GSFileContainer>)container;
- (id)initWithContainer:(id<GSFileContainer>)container andSortOrder:(GSFileContainerSortOrder)sortOrder;

@property (nonatomic) GSFileContainerSortOrder sortOrder;
@property (nonatomic, retain) id<GSFileContainer> container;

@end
