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

@interface GSDirectory() {
    NSString * _visitedMarkerPath;
    BOOL _isVisited;
}

- (void)setContents:(NSArray*)contents;
- (NSString*)visitedMarkerPath;
- (void)sortContents;

@end

@implementation GSDirectory

@synthesize contents=_contents;
@synthesize sortOrder=_sortOrder;

#pragma mark - Object lifecycle

- (id)initWithPath:(NSString *)path
{
    self = [super initWithPath:path];
    if (self) {
        _isVisited = NO;
        _sortOrder = GSFileContainerSortOrderDefault;
    }
    return self;
}

+ (GSDirectory*)directoryWithPath:(NSString*)path
{
    return [[GSDirectory alloc] initWithPath:path];
}

#pragma mark - Visited status accessors

- (NSString*)visitedMarkerPath
{
    if (_visitedMarkerPath == nil) {
        return [self.path stringByAppendingPathComponent:@".visited"];
    }
    return _visitedMarkerPath;
}

- (void)markVisited
{
    [[[NSDate date] description] writeToFile:self.visitedMarkerPath
                                  atomically:NO
                                    encoding:NSUTF8StringEncoding
                                       error:nil];
}

- (BOOL)isVisited {
    if (_isVisited == NO) {
        _isVisited = [[NSFileManager defaultManager] fileExistsAtPath:self.visitedMarkerPath];
    }
    return _isVisited;
}

- (void)removeItemAtIndex:(NSUInteger)index error:(NSError *__autoreleasing *)error
{
    if (index < self.contents.count) {
        GSFileSystemEntity *fse = [self.contents objectAtIndex:index];
        [[NSFileManager defaultManager] removeItemAtPath:fse.path
                                                   error:error];
        [self invalidateContents];
        
    }
}

#pragma mark - Custom accessors

- (NSString*)subtitle
{
    return [NSString stringWithFormat:@"%u %@", self.contents.count, self.contents.count == 1 ? @"item" : @"items"];
}

- (void)setContents:(NSArray *)contents
{
    _contents = contents;
}

- (UIImage*)icon
{
    return [UIImage imageNamed:@"folder-icon.png"];
}

- (BOOL)isDirectory
{
    return YES;
}

- (NSArray*)contents
{
    if (!_contents) {
        NSError *error = nil;
        NSArray *tempContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:&error];
        if (!error) {
            NSMutableArray *tempMutable = [NSMutableArray arrayWithCapacity:tempContents.count];
            for (NSString * filename in tempContents) {
                if ([filename isEqualToString:@"__MACOSX"]) {
                    continue;
                }
                
                // Ignore files starting with a dot
                if ([filename rangeOfString:@"."].location == 0) {
                    continue;
                }
                
                NSString *path = [self.path stringByAppendingPathComponent:filename];
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
            _contents = [NSArray arrayWithArray:tempMutable];
            if (self.sortOrder != GSFileContainerSortOrderDefault) {
                [self sortContents];
            }
        }
    }
    
    // If this directory contains only a single subdirectory, flatten
    // the directory hierarchy by returning the contents of the 
    // subdirectory directly
    if (_contents.count == 1 && [(GSFileSystemEntity*)[_contents objectAtIndex:0] isDirectory]) {
        GSDirectory *singleSubdirectory = [_contents objectAtIndex:0];
        return singleSubdirectory.contents;
    }
    return _contents;
}

- (void)setSortOrder:(GSFileContainerSortOrder)sortOrder
{
    if (sortOrder != _sortOrder) {
        _sortOrder = sortOrder;
        [self sortContents];
    }
}

#pragma mark - Misc methods

- (void)sortContents
{
    switch (self.sortOrder) {
        case GSFileContainerSortOrderByName:
            self.contents = [self.contents sortedArrayUsingComparator:^NSComparisonResult(GSFileSystemEntity * obj1, GSFileSystemEntity * obj2) {
                return [obj1.name compare:obj2.name];
            }];
            break;
        case GSFileContainerSortOrderByModifiedDateNewestFirst:
            self.contents = [self.contents sortedArrayUsingComparator:^NSComparisonResult(GSFileSystemEntity * obj1, GSFileSystemEntity * obj2) {
                return [obj2.attributes.fileModificationDate compare:obj1.attributes.fileModificationDate];
            }];
            break;
        default:
            break;
    }
}

- (void)invalidateContents
{
    _contents = nil;
}

@end
