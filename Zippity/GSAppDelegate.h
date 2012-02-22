//
//  GSAppDelegate.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GSRootListViewController.h"

#define kGSZipFilePathKey @"zipFilePath"

@interface GSAppDelegate : UIResponder <UIApplicationDelegate> {
    NSString * _documentsDirectory;
    NSString * _zipFilesDirectory;
    NSString * _visitedMarkersDirectory;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) GSRootListViewController *rootListViewController;
@property (readonly) NSString *zipFilesDirectory;
@property (readonly) NSString *visitedMarkersDirectory;
@property (readonly) NSString *documentsDirectory;
@property (assign, nonatomic) UINavigationController *navigationController;

@end
