//
//  ZPPreviewController.m
//  Zippity
//
//  Created by Simon Whitaker on 15/04/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPPreviewController.h"

@interface ZPPreviewController ()

@end

@implementation ZPPreviewController

@synthesize originalLeftBarButtonItem = _originalLeftBarButtonItem;

- (void)viewDidLayoutSubviews
{
    if (self.originalLeftBarButtonItem && UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        self.navigationItem.leftBarButtonItem = self.originalLeftBarButtonItem;
    }
}

@end
