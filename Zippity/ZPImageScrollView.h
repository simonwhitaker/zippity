//
//  ZPImageScrollView.h
//  Zippity
//
//  Created by Simon Whitaker on 27/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZPFileWrapper;

@interface ZPImageScrollView : UIScrollView {
}

@property (nonatomic, weak) ZPFileWrapper * imageFileWrapper;
@property (nonatomic) NSUInteger index;
@property (nonatomic, weak) UIImageView * imageView;
@property (nonatomic, weak) UIActivityIndicatorView * activityIndicatorView;

- (void)updateZoomScales;

- (void)handleDoubleTapAtPoint:(CGPoint)point;

@end

