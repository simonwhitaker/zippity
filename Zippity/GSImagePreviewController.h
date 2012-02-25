//
//  GSImagePreviewController.h
//  Zippity
//
//  Created by Simon Whitaker on 25/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GSFileWrapper.h"

@interface GSImagePreviewController : UIViewController

@property (nonatomic, retain) GSFileWrapper * imageFile;

- (void)toggleChromeVisibility;

@end
