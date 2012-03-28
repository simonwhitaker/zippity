//
//  NSDate+GSAdditions.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "NSDate+GSAdditions.h"

@implementation NSDate (GSAdditions)

- (BOOL)isEarlierThanDate:(NSDate*)otherDate
{
    return [self compare:otherDate] == NSOrderedAscending;
}

@end
