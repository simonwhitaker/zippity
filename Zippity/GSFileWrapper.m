//
//  GSFileWrapper.m
//  
//
//  Created by Simon Whitaker on 21/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GSFileWrapper.h"
#import "GSAppDelegate.h"
#import "NSArray+GSZippityAdditions.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "GSArchive.h"


//------------------------------------------------------------
// Public class interface: GSFileWrapper
//------------------------------------------------------------

@interface GSFileWrapper()
- (void)setUrl:(NSURL*)url;
- (void)setAttributes:(NSDictionary*)attributes;
// Allows us to write to self.containerStatus internally
- (void)setContainerStatus:(GSFileWrapperContainerStatus)containerStatus;
// Starts the asynchronous reading of container contents.
- (void)_fetchContainerContents;
@end

//------------------------------------------------------------
// Private class interface: GSDirectoryWrapper
//------------------------------------------------------------

@interface GSDirectoryWrapper : GSFileWrapper
@end

//------------------------------------------------------------
// Private class interface: GSRegularFileWrapper
//------------------------------------------------------------

@interface GSRegularFileWrapper : GSFileWrapper {
    NSNumber * _isImageFileNumberObj;
}
@end

//------------------------------------------------------------
// Private class interface: GSZipFileWrapper
//------------------------------------------------------------

@interface GSArchiveFileWrapper : GSRegularFileWrapper {
    GSFileWrapper * _cacheDirectory;
    NSString * _cachePath;
    NSString * _visitedMarkerPath;
}
@property (readonly) NSString * cachePath;
@property (readonly) NSString * visitedMarkerPath;
@end

//------------------------------------------------------------
// Public class: GSFileWrapper
//------------------------------------------------------------

@implementation GSFileWrapper

@synthesize name=_name;
@synthesize url=_url;
@synthesize sortOrder=_sortOrder;
@synthesize visited=_visited;
@synthesize parent=_parent;

NSString * const GSFileWrapperContainerDidReloadContents = @"GSFileWrapperContainerDidReloadContents";
NSString * const GSFileWrapperContainerDidFailToReloadContents = @"GSFileWrapperContainerDidFailToReloadContents";

#pragma mark - Object lifecycle

static NSSet * SupportedArchiveTypes;

+ (void)initialize
{
    NSMutableSet * tempTypes = [NSMutableSet set];
    NSArray *documentTypes = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleDocumentTypes"];
    for (NSDictionary *documentType in documentTypes) {
        [tempTypes addObjectsFromArray:[documentType valueForKeyPath:@"LSItemContentTypes"]];
    }
    SupportedArchiveTypes = [NSSet setWithSet:tempTypes];
}

- (id)initWithURL:(NSURL*)url error:(NSError**)error
{
    self = [super init];
    if (self) {
        self.url = url;
        self.name = [[url path] lastPathComponent];
        self.attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path]
                                                                           error:error];
        self.containerStatus = GSFileWrapperContainerStatusInitialised;
    }
    if (*error) {
        return nil;
    }
    return self;
}

+ (GSFileWrapper*)fileWrapperWithURL:(NSURL*)url error:(NSError**)error
{
    GSFileWrapper *result;
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory]) {
        if (isDirectory) {
            result = [[GSDirectoryWrapper alloc] initWithURL:url error:error];
        } else {
            UIDocumentInteractionController *ic = [UIDocumentInteractionController interactionControllerWithURL:url];
            if ([SupportedArchiveTypes containsObject:ic.UTI]) {
                result = [[GSArchiveFileWrapper alloc] initWithURL:url error:error];
            } else {
                result = [[GSRegularFileWrapper alloc] initWithURL:url error:error];
            }
            // Save the document interaction controller - no point re-generating it later
            result->_documentInteractionController = ic;
        }
    } else {
        // TODO: File doesn't exist - bomb out
    }
    if (result && *error == nil) {
        return result;
    }
    return nil;
}

- (BOOL)remove:(NSError *__autoreleasing *)error
{
    return [[NSFileManager defaultManager] removeItemAtURL:_url error:error];
}

#pragma mark - Materialised properties

- (NSString*)displayName
{
    if (_displayName == nil) {
        _displayName = [self.name stringByDeletingPathExtension];
    }
    return _displayName;
}

- (NSString*)humanFileSize
{
    return nil;
}

- (NSDictionary*)attributes
{
    return _attributes;
}

- (NSString*)subtitle
{
    return nil;
}

- (UIImage*)icon
{
    if (_icon == nil && self.documentInteractionController.icons.count > 0) {
        _icon = [self.documentInteractionController.icons objectAtIndex:0];
    }
    return _icon;
}

- (UIDocumentInteractionController*)documentInteractionController
{
    if (_documentInteractionController == nil) {
        _documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:self.url];
    }
    return _documentInteractionController;
}

- (BOOL)visited
{
    return NO;
}

#pragma mark - Functionality properties

- (BOOL)isDirectory
{
    return NO;
}

- (BOOL)isRegularFile
{
    return NO;
}

- (BOOL)isArchive
{
    return NO;
}

- (BOOL)isContainer 
{
    return self.isDirectory || self.isArchive;
}

- (BOOL)isImageFile
{
    return NO;
}

#pragma mark - Container methods

- (void)setSortOrder:(GSFileWrapperSortOrder)sortOrder
{
    if (_sortOrder != sortOrder) {
        _sortOrder = sortOrder;
        
        if (_fileWrappers) {
            _fileWrappers = [_fileWrappers sortedArrayUsingFileWrapperSortOrder:sortOrder];
        }
    }
}

- (void)setContainerStatus:(GSFileWrapperContainerStatus)containerStatus
{
    if (containerStatus != _containerStatus) {
        _containerStatus = containerStatus;
        
        if (_containerStatus == GSFileWrapperContainerStatusReady) {
            [[NSNotificationCenter defaultCenter] postNotificationName:GSFileWrapperContainerDidReloadContents
                                                                object:self];
        }
    }
}

- (void)_fetchContainerContents
{
    // Subclasses that return YES to isContainer must implement this method.
    // The method will be called on a background thread so needs its own
    // autorelease pool. 
    // 
    // On success it should set self.containerStatus to
    // GSFileWrapperContainerStatusReady. A pre-formatted NSNotification
    // will be sent automatically.
    //
    // On failure, it should set self.containerStatus to 
    // GSFileWrapperContainerStatusError and send an appropriate 
    // NSNotification with error details in its payload.
    @autoreleasepool {
        NSLog(@"Error - need to override _fetchContainerContents in %@", [self class]);
    }
}

- (GSFileWrapperContainerStatus)containerStatus
{
    return _containerStatus;
}

- (NSArray*)fileWrappers
{
    if (self.isContainer) {
        if (self.containerStatus == GSFileWrapperContainerStatusInitialised) {
            [self _fetchContainerContents];
        }
        return _fileWrappers;
    }
    return nil;
}

- (NSArray*)imageFileWrappers
{
    static NSPredicate * ImageFilePredicate = nil;
    if (ImageFilePredicate == nil) {
        ImageFilePredicate = [NSPredicate predicateWithFormat:@"isImageFile == YES"];
    }
    NSArray *result = [self.fileWrappers filteredArrayUsingPredicate:ImageFilePredicate];
    return result;
}

- (void)reloadContainerContents
{
    if (self.isContainer) {
        self.containerStatus = GSFileWrapperContainerStatusInitialised;
        [self performSelectorInBackground:@selector(_fetchContainerContents) withObject:nil];
    }
}

- (GSFileWrapper*)fileWrapperAtIndex:(NSUInteger)index 
{
    if (self.isContainer) {
        return [_fileWrappers objectAtIndex:index];
    }
    return nil;
}

- (BOOL)removeItemAtIndex:(NSUInteger)index error:(NSError**)error
{
    if (self.isContainer) {
        [[_fileWrappers objectAtIndex:index] remove:error];
    }
    if (*error) {
        return NO;
    } else {
        NSMutableArray *mutableWrappers = [_fileWrappers mutableCopy];
        [mutableWrappers removeObjectAtIndex:index];
        _fileWrappers = [NSArray arrayWithArray:mutableWrappers];
        return YES;
    }
}

#pragma mark - Regular file methods

- (unsigned long long)fileSize
{
    return _attributes.fileSize;
}

#pragma mark - Private ivar accessors

- (void)setUrl:(NSURL *)url
{
    _url = url;
}

- (void)setAttributes:(NSDictionary *)attributes
{
    _attributes = [attributes copy];
}

@end

//------------------------------------------------------------
// Private class: GSDirectoryWrapper
//------------------------------------------------------------

@implementation GSDirectoryWrapper

- (BOOL)isDirectory { 
    return YES; 
}

- (UIImage*)icon
{
    return [UIImage imageNamed:@"folder-icon.png"];
}

- (void)_fetchContainerContents
{
    @autoreleasepool {
        NSError *error = nil;
        NSArray *urls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.url
                                                      includingPropertiesForKeys:nil
                                                                         options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                           error:&error];
        if (error) {
            self.containerStatus = GSFileWrapperContainerStatusError;
            [[NSNotificationCenter defaultCenter] postNotificationName:GSFileWrapperContainerDidFailToReloadContents
                                                                object:self
                                                              userInfo:[NSDictionary dictionaryWithObject:error forKey:kErrorKey]];
        } else {
            NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:urls.count];
            for (NSURL *url in urls) {
                NSString *filename = url.path.lastPathComponent;
                if ([filename isEqualToString:@"__MACOSX"]) {
                    continue;
                }
                
                NSError *initError = nil;
                GSFileWrapper *wrapper = [GSFileWrapper fileWrapperWithURL:url error:&initError];
                if (initError) {
                    self.containerStatus = GSFileWrapperContainerStatusError;
                    [[NSNotificationCenter defaultCenter] postNotificationName:GSFileWrapperContainerDidFailToReloadContents
                                                                        object:self
                                                                      userInfo:[NSDictionary dictionaryWithObject:initError forKey:kErrorKey]];
                    return;
                }
                [tempArray addObject:wrapper];
                wrapper.parent = self;
            }
            if (self.sortOrder) {
                _fileWrappers = [tempArray sortedArrayUsingFileWrapperSortOrder:self.sortOrder];
            } else {
                _fileWrappers = [NSArray arrayWithArray:tempArray];
            }
            
            // Flatten nested folders. If we encounter folders
            // that contain only a single entity which is also a folder,
            // make the contents of the child folder the logical
            // contents of the parent folder. The effect is that the
            // child folder disappears from view.
            // 
            // Turns this:
            // 
            //    a
            //    +-b
            //      +-c
            //        +-foo.txt
            //        +-d
            //          +-e
            //            +-bar.txt
            // 
            // Into this:
            // 
            //    a
            //    +-foo.txt
            //    +-d
            //      +-bar.txt
            if (_fileWrappers.count == 1) {
                GSFileWrapper * childWrapper = [_fileWrappers objectAtIndex:0];
                if (childWrapper.isDirectory) {
                    [childWrapper _fetchContainerContents];
                    _fileWrappers = childWrapper.fileWrappers;
                }
            }

            // Must set parent references AFTER we flatten nested 
            // folders, so that following the inheritance chain
            // back up still works.
            for (GSFileWrapper* wrapper in _fileWrappers) {
                wrapper.parent = self;
            }

            self.containerStatus = GSFileWrapperContainerStatusReady;
        }
    }
}


@end

//------------------------------------------------------------
// Private class: GSRegularFileWrapper
//------------------------------------------------------------

@implementation GSRegularFileWrapper

#define kBytesInKilobyte 1024

- (BOOL)isRegularFile 
{
    return YES; 
}

- (BOOL)isImageFile
{
    // Returns YES if the file is an image type that can be displayed in
    // a UIImage object.
    //
    // UTI types are listed in "System-Declared Uniform Type Identifiers"
    // https://developer.apple.com/library/mac/#documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html
    //
    // UIImage-supported images listed in UIImage class reference. In iOS
    // 4.3 these are:
    //
    // TIFF (.tiff, .tif)
    // JPEG (.jpg, .jpeg)
    // GIF (.gif)
    // PNG (.png)
    // Windows Bitmap Format (DIB) (.bmp, .BMPf)
    // Windows Icon Format (.ico)
    // Windows Cursor (.cur)
    // XWindow bitmap (.xbm)
    
    if (_isImageFileNumberObj == nil) {
        CFStringRef uti = (__bridge CFStringRef)self.documentInteractionController.UTI;
        BOOL result = UTTypeConformsTo(uti, kUTTypeJPEG)
            || UTTypeConformsTo(uti, kUTTypePNG)
            || UTTypeConformsTo(uti, kUTTypeBMP)
            || UTTypeConformsTo(uti, kUTTypeTIFF)
            || UTTypeConformsTo(uti, kUTTypeGIF)
            || UTTypeConformsTo(uti, kUTTypeICO)
            || [[self.name.pathExtension lowercaseString] isEqualToString:@"cur"]
            || [[self.name.pathExtension lowercaseString] isEqualToString:@"xbm"];
        _isImageFileNumberObj = [NSNumber numberWithBool:result];
    }
    return [_isImageFileNumberObj boolValue];
}

- (NSString*)humanFileSize
{
    if (_humanFileSize == nil) {
        static NSArray *SizeSuffixes = nil;
        if (SizeSuffixes == nil) {
            SizeSuffixes = [NSArray arrayWithObjects: @"KB", @"MB", @"GB", nil];
        }
        NSString * sizeString = [NSString stringWithFormat:@"%llu bytes", _attributes.fileSize];
        
        CGFloat sizef = (CGFloat)_attributes.fileSize;
        for (NSString * suffix in SizeSuffixes) {
            if (sizef > kBytesInKilobyte) {
                sizef /= (float)kBytesInKilobyte;
                sizeString = [NSString stringWithFormat:@"%.0f %@", sizef, suffix];
            } else {
                break;
            }
        }
        _humanFileSize = sizeString;
    }
    return _humanFileSize;
}

@end

//------------------------------------------------------------
// Private class: GSZipFileWrapper
//------------------------------------------------------------

@implementation GSArchiveFileWrapper

- (BOOL)isArchive { 
    return YES; 
}

- (void)setSortOrder:(GSFileWrapperSortOrder)sortOrder
{
    _cacheDirectory.sortOrder = sortOrder;
}

- (NSArray*)fileWrappers
{
    if (self.containerStatus == GSFileWrapperContainerStatusReady) {
        return [_cacheDirectory fileWrappers];
    }
    return [super fileWrappers];
}

- (GSFileWrapper*)fileWrapperAtIndex:(NSUInteger)index
{
    return [_cacheDirectory fileWrapperAtIndex:index];
}

- (BOOL)removeItemAtIndex:(NSUInteger)index error:(NSError *__autoreleasing *)error
{
    // Not currently supported for zip files
    return NO;
}

- (BOOL)remove:(NSError *__autoreleasing *)error
{
    [[NSFileManager defaultManager] removeItemAtPath:self.visitedMarkerPath error:nil];
    return [super remove:error];
}

- (NSString*)cachePath
{
    if (_cachePath == nil) {
        GSAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSString *relativePath = [self.url.path stringByReplacingOccurrencesOfString:appDelegate.zipFilesDirectory
                                                                          withString:@""
                                                                             options:0 
                                                                               range:NSMakeRange(0, appDelegate.zipFilesDirectory.length)];
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

- (BOOL)visited
{
    return [[NSFileManager defaultManager] fileExistsAtPath:self.visitedMarkerPath];
}

- (void)setVisited:(BOOL)visited
{
    if (visited) {
        [[[NSDate date] description] writeToFile:self.visitedMarkerPath
                                      atomically:NO 
                                        encoding:NSUTF8StringEncoding
                                           error:nil];
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:self.visitedMarkerPath
                                                   error:nil];
    }
}

- (NSString*)visitedMarkerPath
{
    if (_visitedMarkerPath == nil) {
        GSAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        _visitedMarkerPath = [[appDelegate visitedMarkersDirectory] stringByAppendingPathComponent:self.url.lastPathComponent];
    }
    return _visitedMarkerPath;
}

- (void)_fetchContainerContents
{
    @autoreleasepool {
        // Get the cache directory for this zip file, ensure it's
        // available and newer than the zip file it represents
        NSError * error = nil;
        
        BOOL requiresUnzipping = YES;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.cachePath]) {
            NSDictionary *cacheAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.cachePath error:&error];
            if (error) {
                NSLog(@"Error on getting attributes for cache directory (%@): %@, %@", self.cachePath, error, error.userInfo);
                self.containerStatus = GSFileWrapperContainerStatusError;
                [[NSNotificationCenter defaultCenter] postNotificationName:GSFileWrapperContainerDidFailToReloadContents
                                                                    object:self
                                                                  userInfo:[NSDictionary dictionaryWithObject:error forKey:kErrorKey]];;
                return;
            }
            
            // We need to re-unzip if the cache directory was last modified before
            // the zip file was last modified
            requiresUnzipping = [cacheAttributes.fileModificationDate isEarlierThanDate:_attributes.fileModificationDate];
        }
        
        if (requiresUnzipping) {
            // Delete any current directory contents
            error = nil;
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.cachePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:self.cachePath error:&error];
                if (error) {
                    NSLog(@"Error on deleting existing cache directory (%@): %@, %@", self.cachePath, error, error.userInfo);
                    self.containerStatus = GSFileWrapperContainerStatusError;
                    [[NSNotificationCenter defaultCenter] postNotificationName:GSFileWrapperContainerDidFailToReloadContents
                                                                        object:self
                                                                      userInfo:[NSDictionary dictionaryWithObject:error forKey:kErrorKey]];;
                    return;
                }
            }

            // (Re-)create cache directory
            error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:self.cachePath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if (error) {
                NSLog(@"Error on creating cache directory (%@): %@, %@", self.cachePath, error, error.userInfo);
                self.containerStatus = GSFileWrapperContainerStatusError;
                [[NSNotificationCenter defaultCenter] postNotificationName:GSFileWrapperContainerDidFailToReloadContents
                                                                    object:self
                                                                  userInfo:[NSDictionary dictionaryWithObject:error forKey:kErrorKey]];;
                return;
            }
            
            GSArchive *archive = [[GSArchive alloc] initWithPath:self.url.path];
            NSError *error = nil;
            BOOL success = [archive extractToDirectory:self.cachePath overwrite:YES error:&error];
            if (!success) {
                NSLog(@"Error on extracting archive (%@) to cache directory (%@): %@, %@", self.url.path, self.cachePath, error, [error userInfo]);
            }
        }
        
        _cacheDirectory = [GSFileWrapper fileWrapperWithURL:[NSURL fileURLWithPath:self.cachePath] error:&error];
        self.containerStatus = GSFileWrapperContainerStatusReady;
    }
}

@end
