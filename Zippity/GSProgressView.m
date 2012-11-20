//
//  GSProgressView.m
//  GSProgressIndicatorDemo
//
//  Created by Simon Whitaker on 14/11/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSProgressView.h"
#import <QuartzCore/QuartzCore.h>

@implementation GSProgressView

- (void)commonInit
{
    self.color = [UIColor blackColor];
    self.backgroundColor = [UIColor clearColor];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)setProgress:(CGFloat)progress
{
    if (progress > 1.0) progress = 1.0;
    
    if (progress != _progress) {
        _progress = progress;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect
{
    CGPoint center = CGPointMake(rect.size.width / 2,
                                 rect.size.height / 2);
    CGFloat radius = MIN(rect.size.width, rect.size.height) / 2;

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(ctx, center.x, center.y);
    CGContextAddArc(ctx,
                    center.x,
                    center.y,
                    radius,
                    0 - M_PI_2, // start angle (0 = positive X axis)
                    2 * M_PI * self.progress - M_PI_2, // end angle
                    0); // 0 = anticlockwise, 1 = clockwise
    CGContextClosePath(ctx);
    
    CGContextSetFillColorWithColor(ctx, [self.color CGColor]);
    CGContextFillPath(ctx);
}

@end
