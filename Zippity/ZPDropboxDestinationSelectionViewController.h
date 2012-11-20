//
//  ZPDropboxDestinationSelectionViewController.h
//  Zippity
//
//  Created by Simon Whitaker on 06/11/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZPDropboxDestinationSelectionViewControllerDelegate;

@interface ZPDropboxDestinationSelectionViewController : UITableViewController

@property (nonatomic, strong) NSString *rootPath;
@property (nonatomic, weak) id<ZPDropboxDestinationSelectionViewControllerDelegate> delegate;

@end

@protocol ZPDropboxDestinationSelectionViewControllerDelegate <NSObject>

- (void)dropboxDestinationSelectionViewController:(ZPDropboxDestinationSelectionViewController*)viewController
                         didSelectDestinationPath:(NSString *)destinationPath;
- (void)dropboxDestinationSelectionViewControllerDidCancel:(ZPDropboxDestinationSelectionViewController*)viewController;

@end