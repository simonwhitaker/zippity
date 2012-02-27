//
//  GSImageScrollView.m
//  Zippity
//
//  Created by Simon Whitaker on 27/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSImageScrollView.h"

@implementation GSImageScrollView

@synthesize imageView=_imageView;
@synthesize page=_page;

//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code
//    }
//    return self;
//}

- (void)setImageView:(UIImageView *)imageView
{
    if (imageView != _imageView) {
        for (UIView *v in self.subviews) {
            [v removeFromSuperview];
        }
        if (imageView) {
            imageView.frame = self.bounds;
            [self addSubview:imageView];
            
            self.minimumZoomScale = 1.0;
            
            CGFloat widthScaleFactor = imageView.image.size.width / self.frame.size.width;
            CGFloat heightScaleFactor = imageView.image.size.height / self.frame.size.height;
            self.maximumZoomScale = widthScaleFactor > heightScaleFactor ? widthScaleFactor : heightScaleFactor;
        }
        _imageView = imageView;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.imageView.frame;
    
    // centre horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // centre vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    } else {
        frameToCenter.origin.y = 0;
    }
    
    self.imageView.frame = frameToCenter;
}

@end
