//
//  GSZipFile.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSZipFile.h"

@implementation GSZipFile

@synthesize name=_name;
@synthesize path=_path;

- (id)init
{
    self = [super init];
    if (self) {
        _length = 0;
    }
    return self;
}

- (id)initWithPath:(NSString *)path
{
    self = [self init];
    if (self) {
        self.path = path;
    }
    return self;
}

+ (GSZipFile*)zipFileWithPath:(NSString *)path
{
    GSZipFile *z = [[GSZipFile alloc] initWithPath:path];
    return z;
}

- (NSString *)name
{
    if (_name == nil) {
        NSFileManager *fm = [NSFileManager defaultManager];
        _name = [fm displayNameAtPath:self.path];
    }
    return _name;
}

- (unsigned long long)length
{
    NSLog(@"NSUInteger size: %lu bytes", sizeof(NSUInteger));
    
    if (_length == 0) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError * error = nil;
        NSDictionary *d = [fm attributesOfItemAtPath:self.path
                                               error:&error];
        if (error) {
            NSLog(@"Error on getting file attributes: %@, %@", error, error.userInfo);
        } else {
            _length = [[d objectForKey:NSFileSize] unsignedLongLongValue];
        }
    }
    return _length;
}

- (NSString *)displayLength
{
    return [NSString stringWithFormat:@"%llu bytes", self.length];
}

@end
