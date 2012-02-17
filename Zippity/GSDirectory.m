//
//  GSDirectory.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSDirectory.h"
#import "GSFile.h"
#import "GSZipFile.h"
#import "NSArray+GSAdditions.h"

@implementation GSDirectory

+ (GSDirectory*)directoryWithPath:(NSString*)path
{
    return [[GSDirectory alloc] initWithPath:path];
}

- (NSString*)subtitle
{
    return [NSString stringWithFormat:@"%u %@", self.contents.count, self.contents.count == 1 ? @"item" : @"items"];
}

- (NSArray*)contents
{
    if (!_contents) {
        _contents = [NSArray arrayWithFilesFromDirectory:self.path];
    }
    return _contents;
}

- (void)invalidateContents
{
    _contents = nil;
}

- (UIImage*)icon
{
    return [UIImage imageNamed:@"folder-icon-somatic-rebirth.png"];
}

@end
