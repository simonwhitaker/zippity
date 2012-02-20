//
//  GSZipFile.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSZipFile.h"
#import "ZipArchive.h"
#import "GSDirectory.h"
#import "GSAppDelegate.h"

@interface GSZipFile()

- (void)populateContents;
- (void)setStatus:(GSZipFileUnzipStatus)status; // lets us call self.status internally

@property (nonatomic, readonly) GSDirectory * cacheDirectory;
@property (nonatomic, copy) NSString * cachePath;

@end

@implementation GSZipFile

@synthesize status=_status;
@synthesize cachePath=_cachePath;
@synthesize cacheDirectory=_cacheDirectory;
@synthesize sortOrder=_sortOrder;

NSString * const GSZipFileDidUpdateUnzipStatus = @"GSZipFileDidUpdateUnzipStatus";

#pragma mark - Object lifecycle

- (id)initWithPath:(NSString *)path
{
    self = [super initWithPath:path];
    if (self) {
        self.status = GSZipFileUnzipStatusInitialized;
        [self performSelectorInBackground:@selector(populateContents) withObject:nil];
    }
    return self;
}

+ (GSZipFile*)zipFileWithPath:(NSString *)path
{
    GSZipFile *z = [[GSZipFile alloc] initWithPath:path];
    return z;
}

- (void)remove:(NSError *__autoreleasing *)error
{
    NSError *cacheDirError = nil;
    [self.cacheDirectory remove:&cacheDirError];
    if (cacheDirError) {
        NSLog(@"Error deleting %@: %@, %@", self.cacheDirectory, cacheDirError, cacheDirError.userInfo);
    }
    [super remove:error];
}

- (void)removeItemAtIndex:(NSUInteger)index error:(NSError *__autoreleasing *)error
{
    [self.cacheDirectory removeItemAtIndex:index error:error];
}

#pragma mark - Custom accessors

- (void)setStatus:(GSZipFileUnzipStatus)status
{
    if (_status != status) {
        _status = status;
        NSDictionary *notificationPayload = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:status] 
                                                                        forKey:kZipFileStatusKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:GSZipFileDidUpdateUnzipStatus
                                                            object:self
                                                          userInfo:notificationPayload];
    }
}

- (NSString*)cachePath
{
    if (_cachePath == nil) {
        GSAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSString *relativePath = [self.path stringByReplacingOccurrencesOfString:appDelegate.rootDirectory
                                                                      withString:@""
                                                                         options:0 
                                                                           range:NSMakeRange(0, appDelegate.rootDirectory.length)];
        NSString *finalDirectoryName = [relativePath stringByAppendingString:@".contents"];

        NSString *cacheBasePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSArray * pathComponents = [NSArray arrayWithObjects:
                                    cacheBasePath,
                                    finalDirectoryName,
                                    nil];
        _cachePath = [NSString pathWithComponents:pathComponents];
    }
    return _cachePath;
}

- (BOOL)isVisited
{
    return self.cacheDirectory.isVisited;
}

- (NSArray*)contents
{
    return self.cacheDirectory.contents;
}

- (void)setSortOrder:(GSFileContainerSortOrder)sortOrder
{
    self.cacheDirectory.sortOrder = sortOrder;
}

#pragma mark - Misc methods

- (void)markVisited
{
    [self.cacheDirectory markVisited];
}

- (void)invalidateContents
{
    _cacheDirectory = nil;
    self.status = GSZipFileUnzipStatusInitialized;
    [[NSFileManager defaultManager] removeItemAtPath:self.cachePath error:nil];
    [self performSelectorInBackground:@selector(populateContents)
                           withObject:nil];
}

- (void)populateContents
{
    @autoreleasepool {
        if (self.cacheDirectory) {
            self.status = GSZipFileUnzipStatusComplete;
            return;
        }
        
        // Get the cache directory for this zip file, ensure it's
        // available and newer than the zip file it represents
        NSError * error = nil;
        
        BOOL requiresUnzipping = YES;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.cachePath]) {
            NSDictionary *cacheAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.cachePath error:&error];
            if (error) {
                NSLog(@"Error on getting attributes for cache directory (%@): %@, %@", self.cachePath, error, error.userInfo);
                self.status = GSZipFileUnzipStatusError;
                return;
            }
            
            // We need to re-unzip if the cache directory was last modified before
            // the zip file was last modified
            requiresUnzipping = [cacheAttributes.fileModificationDate isEarlierThanDate:self.attributes.fileModificationDate];
        } else {
            error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:self.cachePath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if (error) {
                NSLog(@"Error on creating cache directory (%@): %@, %@", self.cachePath, error, error.userInfo);
            }
        }
        
        if (requiresUnzipping) {
            // Delete any current directory contents
            error = nil;
            NSArray *existingFilenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.cachePath error:&error];
            if (error) {
                NSLog(@"Error on deleting existing contents of cache directory (%@): %@, %@", self.cachePath, error, error.userInfo);
                self.status = GSZipFileUnzipStatusError;
                return;
            }
            
            for (NSString *filename in existingFilenames) {
                error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:[self.cachePath stringByAppendingPathComponent:filename] error:&error];
                if (error) {
                    // TODO: add appropriate error handling
                }
            }
            
            self.status = GSZipFileUnzipStatusUnzipping;
            ZipArchive *za = [[ZipArchive alloc] init];
            if ([za UnzipOpenFile:self.path]) {
                BOOL unzipped = [za UnzipFileTo:self.cachePath overWrite:YES];
                if (!unzipped) {
                    NSLog(@"Couldn't unzip file (%@) to cache directory (%@)", self.path, self.cachePath);
                }
            } else {
                NSLog(@"Couldn't open zip file: %@", self.path);
            }
        }
        
        _cacheDirectory = [GSDirectory directoryWithPath:self.cachePath];
        self.status = GSZipFileUnzipStatusComplete;
    }
}

@end
