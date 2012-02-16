//
//  GSFile.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSFile.h"

@implementation GSFile

- (id)init
{
    self = [super init];
    if (self) {
        _size = 0;
    }
    return self;
}

+ (GSFile*)fileWithPath:(NSString *)path
{
    return [[GSFile alloc] initWithPath:path];
}

- (unsigned long long)size
{    
    if (_size == 0) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError * error = nil;
        NSDictionary *d = [fm attributesOfItemAtPath:self.path
                                               error:&error];
        if (error) {
            NSLog(@"Error on getting file attributes: %@, %@", error, error.userInfo);
        } else {
            _size = [d fileSize];
        }
    }
    return _size;
}

- (NSString*)subtitle
{
    return [NSString stringWithFormat:@"%llu bytes", self.size];
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
