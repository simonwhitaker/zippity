//
//  GSAppDelegate.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GSFileContainerListViewController.h"

@interface GSAppDelegate : UIResponder <UIApplicationDelegate> {
    NSString * _documentsDirectory;
    NSString * _archiveFilesDirectory;
    NSString * _visitedMarkersDirectory;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) GSFileContainerListViewController *rootListViewController;
@property (readonly) NSString *archiveFilesDirectory;
@property (readonly) NSString *visitedMarkersDirectory;
@property (readonly) NSString *documentsDirectory;
@property (assign, nonatomic) UINavigationController *navigationController;

@end
