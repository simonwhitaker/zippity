//
//  NSArray+ZPAdditions.h
//  Zippity
//
//  Created by Simon Whitaker on 21/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZPFileWrapper.h"

@interface NSArray (ZPAdditions)

- (NSArray*)sortedArrayUsingFileWrapperSortOrder:(ZPFileWrapperSortOrder)sortOrder;

@end
