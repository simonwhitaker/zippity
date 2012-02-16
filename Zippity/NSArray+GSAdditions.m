//
//  NSArray+GSAdditions.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "NSArray+GSAdditions.h"
#import "GSDirectory.h"
#import "GSFile.h"
#import "GSZipFile.h"

@implementation NSArray (GSAdditions)

+ (NSArray*)arrayWithFilesFromDirectory:(NSString*)directoryPath
{
    NSError *error = nil;
    NSArray *tempContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
    if (!error) {
        NSMutableArray *tempMutable = [NSMutableArray arrayWithCapacity:tempContents.count];
        for (NSString * filename in tempContents) {
            if ([filename isEqualToString:@"__MACOSX"]) {
                continue;
            }
            
            NSString *path = [directoryPath stringByAppendingPathComponent:filename];
            BOOL isDirectory = NO;
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
            
            if (fileExists && isDirectory) {
                [tempMutable addObject:[GSDirectory directoryWithPath:path]];
            } else if ([[[path pathExtension] lowercaseString] isEqualToString:@"zip"]) {
                [tempMutable addObject:[GSZipFile zipFileWithPath:path]];
            } else {
                [tempMutable addObject:[GSFile fileWithPath:path]];
            }
        }
        return [NSArray arrayWithArray:tempMutable];
    }
    return nil;
}

@end
