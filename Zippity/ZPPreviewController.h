//
//  ZPPreviewController.h
//  Zippity
//
//  Created by Simon Whitaker on 15/04/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <QuickLook/QuickLook.h>

@interface ZPPreviewController : QLPreviewController

// QLPreviewController sets its own navigation item buttons once it's rendered
// its content. Using originalLeftBarButtonItem, we'll store a copy
// of the left bar button item (the button to launch the popover controller
// on iPad in portrait mode) and re-add it to the navigation item once the
// preview view is rendered, in [self viewDidLayoutSubviews].
@property (nonatomic, strong) UIBarButtonItem * originalLeftBarButtonItem;

@end
