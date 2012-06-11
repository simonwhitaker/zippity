//
//  ZPEncodingPickerViewController.h
//  Zippity
//
//  Created by Simon Whitaker on 09/06/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GSDismissableViewControllerDelegate.h"

@interface ZPEncodingPickerViewController : UITableViewController

@property (nonatomic, strong) NSData * sampleFilenameCString;
@property (nonatomic, weak) id<GSDismissableViewControllerDelegate> delegate;

- (void)cancel;

@end
