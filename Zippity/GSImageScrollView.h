//
//  GSImageScrollView.h
//  Zippity
//
//  Created by Simon Whitaker on 27/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GSImageScrollView : UIScrollView

@property (nonatomic, assign) UIImageView * imageView;
@property (nonatomic) NSUInteger page;
@end
