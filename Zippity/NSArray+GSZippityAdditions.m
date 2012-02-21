//
//  NSArray+GSZippityAdditions.m
//  Zippity
//
//  Created by Simon Whitaker on 21/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "NSArray+GSZippityAdditions.h"

@implementation NSArray (GSZippityAdditions)

- (NSArray*)sortedArrayUsingFileWrapperSortOrder:(GSFileWrapperSortOrder)sortOrder {
    NSArray *result;
    
    switch (sortOrder) {
        case GSFileWrapperSortOrderByName:
            result = [self sortedArrayUsingComparator:^NSComparisonResult(GSFileWrapper * obj1, GSFileWrapper * obj2) {
                return [obj1.name compare:obj2.name];
            }];
            break;
        case GSFileWrapperSortOrderByModificationDateNewestFirst:
            result = [self sortedArrayUsingComparator:^NSComparisonResult(GSFileWrapper * obj1, GSFileWrapper * obj2) {
                return [obj2.attributes.fileModificationDate compare:obj1.attributes.fileModificationDate];
            }];
            break;
        default:
            result = self;
            break;
    }
    
    return result;
}

@end
