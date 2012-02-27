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
@synthesize index=_index;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIImageView * iv = [[UIImageView alloc] initWithFrame:self.bounds];
        iv.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        iv.contentMode = UIViewContentModeCenter;
        [self addSubview:iv];
        _imageView = iv;
    }
    return self;
}

- (void)displayImage:(UIImage *)image
{
    self.imageView.image = image;
    [self updateZoomScales];
}

- (void)updateZoomScales {
    // Work out the minimum, maximum and initial scale factors
    //
    // For images that exceed the dimensions of the view port,
    // we want to be able to zoom in to full size and out until
    // they fit the viewport
    //
    // For images smaller than the dimensions of the view port,
    // we want to be able to zoom in until they fit the
    // viewport, and zoom out until they're full size.
    //
    // The image is oversized if either of its dimensions is
    // greater than the 
    CGFloat widthScaleFactor = self.imageView.image.size.width / self.frame.size.width;
    CGFloat heightScaleFactor = self.imageView.image.size.height / self.frame.size.height;
    
    CGFloat maxScaleFactor = MAX(widthScaleFactor, heightScaleFactor);
    
    BOOL isOversized = maxScaleFactor > 1.0;
    
    if (isOversized) {
        self.maximumZoomScale = 1.0;
        self.minimumZoomScale = 1 / maxScaleFactor;
    } else {
        self.minimumZoomScale = 1.0;
        self.maximumZoomScale = 1 / maxScaleFactor;
    }
    self.zoomScale = self.minimumZoomScale;
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
