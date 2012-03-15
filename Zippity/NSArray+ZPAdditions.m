//
//  NSArray+ZPAdditions.m
//  Zippity
//
//  Created by Simon Whitaker on 21/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "NSArray+ZPAdditions.h"

@implementation NSArray (ZPAdditions)

- (NSArray*)sortedArrayUsingFileWrapperSortOrder:(ZPFileWrapperSortOrder)sortOrder {
    NSArray *result;
    
    switch (sortOrder) {
        case ZPFileWrapperSortOrderByName:
            result = [self sortedArrayUsingComparator:^NSComparisonResult(ZPFileWrapper * obj1, ZPFileWrapper * obj2) {
                return [obj1.name compare:obj2.name];
            }];
            break;
        case ZPFileWrapperSortOrderByModificationDateNewestFirst:
            result = [self sortedArrayUsingComparator:^NSComparisonResult(ZPFileWrapper * obj1, ZPFileWrapper * obj2) {
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
