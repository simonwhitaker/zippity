//
//  GSAppDelegate.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kGSZipFilePathKey @"zipFilePath"

@interface GSAppDelegate : UIResponder <UIApplicationDelegate> {
@private
    NSString *_rootDirectory;
}

extern NSString * const GSAppReceivedZipFileNotification;

@property (strong, nonatomic) UIWindow *window;
@property (readonly, nonatomic) NSString *rootDirectory;
@property (assign, nonatomic) UINavigationController *navigationController;

@end
