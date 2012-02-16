//
//  GSFileSystemEntity.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSFileSystemEntity.h"

@implementation GSFileSystemEntity

@synthesize name=_name;
@synthesize path=_path;

- (id)initWithPath:(NSString *)path
{
    self = [self init];
    if (self) {
        self.path = path;
    }
    return self;
}

- (NSString *)name
{
    if (_name == nil) {
        _name = [self.path lastPathComponent];
    }
    return _name;
}

- (NSURL *)url 
{
    return [NSURL fileURLWithPath:self.path];
}

- (NSString *)subtitle
{
    return nil;
}

- (NSDictionary*)attributes
{
    if (_attributes == nil) {
        _attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil];
    }
    return _attributes;
}



@end
