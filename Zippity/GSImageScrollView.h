//
//  GSImageScrollView.h
//  Zippity
//
//  Created by Simon Whitaker on 27/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GSFileWrapper;

@interface GSImageScrollView : UIScrollView {
}

@property (nonatomic, weak) GSFileWrapper * imageFileWrapper;
@property (nonatomic) NSUInteger index;
@property (nonatomic, weak) UIImageView * imageView;
@property (nonatomic, weak) UIActivityIndicatorView * activityIndicatorView;

- (void)updateZoomScales;

- (void)handleDoubleTapAtPoint:(CGPoint)point;

@end

