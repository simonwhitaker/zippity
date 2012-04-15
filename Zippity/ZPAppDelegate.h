//
//  GSAppDelegate.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZPFileContainerListViewController.h"

@interface ZPAppDelegate : UIResponder <UIApplicationDelegate, UISplitViewControllerDelegate> {
    NSString * _documentsDirectory;
    NSString * _archiveFilesDirectory;
    NSString * _cacheDirectory;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ZPFileContainerListViewController *rootListViewController;
@property (readonly) NSString *archiveFilesDirectory;
@property (readonly) NSString *documentsDirectory;
@property (readonly) NSString *cacheDirectory;
@property (weak, nonatomic) UINavigationController *navigationController;

// iPad-only stuff
@property (strong, nonatomic) UISplitViewController *splitViewController;
@property (strong, nonatomic) UINavigationController *detailViewNavigationController;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;

- (void)applyTintToDetailViewNavigationController;
- (void)setDetailViewController:(UIViewController*)viewController;
- (void)dismissMasterPopover;

@end
