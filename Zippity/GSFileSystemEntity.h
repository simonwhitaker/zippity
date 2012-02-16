//
//  GSFileSystemEntity.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GSFileSystemEntity : NSObject {
@private
    NSDictionary * _attributes;
}

@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * path;
@property (nonatomic, readonly) NSURL * url;
@property (nonatomic, readonly) NSString * subtitle;
@property (nonatomic, readonly) NSDictionary * attributes;

- (id)initWithPath:(NSString*)path;

@end
