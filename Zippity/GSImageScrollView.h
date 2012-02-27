//
//  GSImageScrollView.h
//  Zippity
//
//  Created by Simon Whitaker on 27/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GSImageScrollView : UIScrollView {
    __unsafe_unretained UIImageView * _imageView;
}

@property (nonatomic) NSUInteger index;
@property (nonatomic, readonly, assign) UIImageView * imageView;

- (void)displayImage:(UIImage*)image;
- (void)updateZoomScales;

- (void)handleDoubleTapAtPoint:(CGPoint)point;

@end

