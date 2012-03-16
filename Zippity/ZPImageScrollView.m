//
//  ZPImageScrollView.m
//  Zippity
//
//  Created by Simon Whitaker on 27/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPImageScrollView.h"
#import "ZPFileWrapper.h"

@implementation ZPImageScrollView

@synthesize imageView=_imageView;
@synthesize index=_index;
@synthesize imageFileWrapper=_imageFileWrapper;
@synthesize activityIndicatorView=_activityIndicatorView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIImageView * iv = [[UIImageView alloc] initWithFrame:self.bounds];
        iv.backgroundColor = [UIColor blackColor];
        [self addSubview:iv];
        self.imageView = iv;
        
        UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        aiv.center = iv.center;
        aiv.hidesWhenStopped = YES;
        [self addSubview:aiv];
        self.activityIndicatorView = aiv;
    }
    return self;
}

- (void)setImageFileWrapper:(ZPFileWrapper *)imageFileWrapper
{
    if (_imageFileWrapper != imageFileWrapper) {
        self.imageView.image = nil;
        
        // Remove any existing notifications
        if (_imageFileWrapper) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:ZPFileWrapperGeneratedPreviewImage
                                                          object:_imageFileWrapper];
        }
        
        // Flip self.imageFileWrapper to point to the new value
        _imageFileWrapper = imageFileWrapper;
        
        // Set up a notification on ZPFileWrapperGeneratedPreviewImage for
        // the new image file before we call displayImage on it, since there's
        // otherwise a race condition where by the time displayImage returns nil 
        // it's already created the preview image, so we never get the
        // notification
        if (_imageFileWrapper) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(displayImage) 
                                                         name:ZPFileWrapperGeneratedPreviewImage
                                                       object:_imageFileWrapper];
        }
        [self displayImage];
    }
}

- (void)displayImage
{
    if (self.imageFileWrapper.displayImage) {
        [self.activityIndicatorView stopAnimating];
        self.zoomScale = 1.0;
        UIImage *image = self.imageFileWrapper.displayImage;
        
        self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
        self.imageView.image = image;
        
        [self updateZoomScales];
        [self setNeedsLayout];
    } else {
        [self.activityIndicatorView startAnimating];
    }
}

- (void)updateZoomScales {
    // Work out the minimum, maximum and initial scale factors
    //
    // For images that exceed the dimensions of the view port,
    // we want to be able to zoom in to full size and out until
    // they fit the viewport
    CGFloat minimumWidthScale = self.frame.size.width / (self.imageView.frame.size.width / self.zoomScale);
    CGFloat minimumHeightScale = self.frame.size.height / (self.imageView.frame.size.height / self.zoomScale);
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
