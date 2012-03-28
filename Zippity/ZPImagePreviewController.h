//
//  GSImagePreviewController.h
//  Zippity
//
//  Created by Simon Whitaker on 25/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZPFileWrapper.h"
#import "ZPImageScrollView.h"

@interface ZPImagePreviewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate>

@property (nonatomic, retain) NSArray * imageFileWrappers;
@property (nonatomic) NSUInteger initialIndex;
@property (nonatomic, assign) IBOutlet UIScrollView * scrollView;

- (ZPImageScrollView*)dequeueReusablePage;

@end
