//
//  ZPUnrecognisedFileTypeViewController.h
//  Zippity
//
//  Created by Simon Whitaker on 09/03/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZPFileWrapper.h"

@interface ZPUnrecognisedFileTypeViewController : UIViewController

@property (nonatomic, weak) ZPFileWrapper * fileWrapper;
@property (nonatomic, weak) IBOutlet UILabel * filenameLabel;

- (id)initWithFileWrapper:(ZPFileWrapper*)fileWrapper;

@end
