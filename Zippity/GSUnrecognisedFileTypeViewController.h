//
//  GSUnrecognisedFileTypeViewController.h
//  Zippity
//
//  Created by Simon Whitaker on 09/03/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GSFileWrapper.h"

@interface GSUnrecognisedFileTypeViewController : UIViewController

@property (nonatomic, weak) GSFileWrapper * fileWrapper;
@property (nonatomic, weak) IBOutlet UILabel * filenameLabel;

- (id)initWithFileWrapper:(GSFileWrapper*)fileWrapper;

@end
