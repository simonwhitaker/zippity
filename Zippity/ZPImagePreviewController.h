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

@protocol ZPImagePreviewControllerDelegate;

@interface ZPImagePreviewController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) NSArray * imageFileWrappers;
@property (nonatomic) NSUInteger initialIndex;
@property (nonatomic, weak) IBOutlet UIScrollView * scrollView;
@property (nonatomic, weak) id<ZPImagePreviewControllerDelegate> delegate;
@property (nonatomic, weak) UIActionSheet * actionSheet;

- (ZPImageScrollView*)dequeueReusablePage;

@end

@protocol ZPImagePreviewControllerDelegate <NSObject>

- (void)imagePreviewControllerDidShowImageForFileWrapper:(ZPFileWrapper*)fileWrapper;

@end
