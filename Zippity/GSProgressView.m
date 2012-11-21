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
    CGPoint center = CGPointMake(rect.size.width/2, rect.size.height/2);
    CGFloat radius = MIN(rect.size.width, rect.size.height)/2;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:center];
    [path addArcWithCenter:center
                    radius:radius
                startAngle:0 - M_PI_2
                  endAngle:2 * M_PI * self.progress - M_PI_2
                 clockwise:YES];
    [path closePath];
    
    if (self.progress == 1.0) {
        UIBezierPath *tickPath = [UIBezierPath bezierPath];
        CGFloat tickWidth = radius/3;
        [tickPath moveToPoint:CGPointMake(0, 0)];
        [tickPath addLineToPoint:CGPointMake(0, tickWidth * 2)];
        [tickPath addLineToPoint:CGPointMake(tickWidth * 3, tickWidth * 2)];
        [tickPath addLineToPoint:CGPointMake(tickWidth * 3, tickWidth)];
        [tickPath addLineToPoint:CGPointMake(tickWidth, tickWidth)];
        [tickPath addLineToPoint:CGPointMake(tickWidth, 0)];
        [tickPath closePath];
        
        [tickPath applyTransform:CGAffineTransformMakeRotation(-M_PI_4)];
        [tickPath applyTransform:CGAffineTransformMakeTranslation(radius * 0.43, radius)];
        
        // Account for non-square views
        CGFloat xOffset = rect.size.width/2 - radius;
        CGFloat yOffset = rect.size.height/2 - radius;
        [tickPath applyTransform:CGAffineTransformMakeTranslation(xOffset, yOffset)];
        
        [path appendPath:tickPath];
    };
    path.usesEvenOddFillRule = YES;
    
    [self.color setFill];
    [path fill];
}

@end
