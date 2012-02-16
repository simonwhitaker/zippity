//
//  GSFile.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSFile.h"

@implementation GSFile

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

+ (GSFile*)fileWithPath:(NSString *)path
{
    return [[GSFile alloc] initWithPath:path];
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

- (unsigned long long)length
{    
    if (_length == 0) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError * error = nil;
        NSDictionary *d = [fm attributesOfItemAtPath:self.path
                                               error:&error];
        if (error) {
            NSLog(@"Error on getting file attributes: %@, %@", error, error.userInfo);
        } else {
            _length = [d fileSize];
        }
    }
    return _length;
}

- (NSString *)displayLength
{
    return [NSString stringWithFormat:@"%llu bytes", self.length];
}

- (NSDictionary*)attributes
{
    if (_attributes == nil) {
        _attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil];
    }
    return _attributes;
}

#pragma QLPreviewController delegate methods

- (NSInteger) numberOfPreviewItemsInPreviewController: (QLPreviewController *) controller
{
    return 1;
}

- (id <QLPreviewItem>) previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    return self.url;
}

@end
