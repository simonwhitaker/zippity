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
        [self addSubview:iv];
        _imageView = iv;
    }
    return self;
}

- (void)displayImage:(UIImage *)image
{
    self.zoomScale = 1.0;
    self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    self.imageView.image = image;
    
    [self updateZoomScales];
    [self setNeedsLayout];
}

- (void)updateZoomScales {
    // Work out the minimum, maximum and initial scale factors
    //
    // For images that exceed the dimensions of the view port,
    // we want to be able to zoom in to full size and out until
    // they fit the viewport
    CGFloat minimumWidthScale = self.frame.size.width / self.imageView.frame.size.width;
    CGFloat minimumHeightScale = self.frame.size.height / self.imageView.frame.size.height;
    CGFloat minimumZoomScale = MIN(minimumWidthScale, minimumHeightScale);
    self.minimumZoomScale = MIN(1.0, minimumZoomScale);
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

- (void)handleDoubleTapAtPoint:(CGPoint)point
{
    float newZoomFactor;
    if (self.zoomScale == self.minimumZoomScale) {
        newZoomFactor = self.maximumZoomScale;
    } else {
        newZoomFactor = self.minimumZoomScale;
    }
    
    if (newZoomFactor == self.zoomScale) {
        return;
    }
    
    NSLog(@"Zooming to new zoom scale factor: %.2f", newZoomFactor);
    CGRect zoomRect = [self zoomRectForScale:newZoomFactor withCenter:point];
    [self zoomToRect:zoomRect animated:YES];
}
                       
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center 
{
    CGRect zoomRect;

    // the zoom rect is in the content view's coordinates. 
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = self.imageView.frame.size.height / scale;
    zoomRect.size.width  = self.imageView.frame.size.width  / scale;

    // choose an origin so as to get the right center.
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);

    return zoomRect;
}

@end
