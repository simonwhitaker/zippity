//
//  GSFileContainer.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GSFileContainer <NSObject>

typedef enum {
    GSFileContainerSortOrderByName,
    GSFileContainerSortOrderByModifiedDateNewestFirst,
    GSFileContainerSortOrderDefault = GSFileContainerSortOrderByName
} GSFileContainerSortOrder;

@property (nonatomic, readonly) NSArray * contents;

// invalidateContents invalidates the previously
// determined, and cached, array of contents, forcing
// them to be rediscovered next time self.contents is
// called.
- (void)invalidateContents;
- (void)sortContentsUsingSortOrder:(GSFileContainerSortOrder)sortOrder;

@end
