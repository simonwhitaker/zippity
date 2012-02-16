//
//  GSDirectory.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSFileSystemEntity.h"
#import "GSFileContainer.h"

@interface GSDirectory : GSFileSystemEntity <GSFileContainer> {
@private
    NSArray * _contents;
}

+ (GSDirectory*)directoryWithPath:(NSString*)path;

@end
