//
//  GSFile.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSFileSystemEntity.h"

@interface GSFile : GSFileSystemEntity {

@private
    unsigned long long _size;
    NSString * _subtitle;
}

@property (nonatomic, readonly) unsigned long long size;

+ (GSFile*)fileWithPath:(NSString*)path;

@end
