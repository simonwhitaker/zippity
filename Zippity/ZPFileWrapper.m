//
//  ZPFileWrapper.m
//  
//
//  Created by Simon Whitaker on 21/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "ZPAppDelegate.h"
#import "ZPArchive.h"
#import "ZPFileWrapper.h"

#define kBytesInKilobyte 1024
#define kDisplayImageMaxDimension 1250.0
#define kSuccessfullyExtractedMarkerFile @".successfullyExtracted"

NSString * const ZPFileWrapperGeneratedPreviewImageNotification = @"ZPFileWrapperGeneratedPreviewImageNotification";
NSString * const ZPFileWrapperContainerDidReloadContents = @"ZPFileWrapperContainerDidReloadContents";
NSString * const ZPFileWrapperContainerDidFailToReloadContents = @"ZPFileWrapperContainerDidFailToReloadContents";

NSString * const ZPFileWrapperErrorDomain = @"ZPFileWrapperErrorDomain";


//------------------------------------------------------------
// Public class interface: ZPFileWrapper
//------------------------------------------------------------

@interface ZPFileWrapper()
- (void)setUrl:(NSURL*)url;
- (void)setAttributes:(NSDictionary*)attributes;
// Allows us to write to self.containerStatus internally
- (void)setContainerStatus:(ZPFileWrapperContainerStatus)containerStatus;
// Starts the asynchronous reading of container contents.
- (void)_fetchContainerContents;
@end

//------------------------------------------------------------
// Private class interface: ZPDirectoryWrapper
//------------------------------------------------------------

@interface ZPDirectoryWrapper : ZPFileWrapper
@end

//------------------------------------------------------------
// Private class interface: ZPRegularFileWrapper
//------------------------------------------------------------

@interface ZPRegularFileWrapper : ZPFileWrapper {
    NSNumber * _isImageFileNumberObj;
}
@property BOOL isQueuedForImageResizing;
@end

//------------------------------------------------------------
// Private class interface: ZPArchiveFileWrapper
//------------------------------------------------------------

@interface ZPArchiveFileWrapper : ZPRegularFileWrapper {
    ZPFileWrapper * _cacheDirectory;
    NSString * _cachePath;
}
@property (readonly) NSString * cachePath;
@end

//------------------------------------------------------------
// Public class: ZPFileWrapper
//------------------------------------------------------------

@implementation ZPFileWrapper

@synthesize name=_name;
@synthesize url=_url;
@synthesize parent=_parent;

#pragma mark - Object lifecycle

static NSArray * SupportedArchiveTypes;

+ (void)initialize
{
    NSMutableArray * tempTypes = [NSMutableArray array];
    NSArray *documentTypes = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleDocumentTypes"];
    for (NSDictionary *documentType in documentTypes) {
        [tempTypes addObjectsFromArray:[documentType valueForKeyPath:@"LSItemContentTypes"]];
    }
    SupportedArchiveTypes = [NSArray arrayWithArray:tempTypes];
}

- (id)initWithURL:(NSURL*)url error:(NSError**)error
{
    self = [super init];
    if (self) {
        self.url = url;
        self.name = [[url path] lastPathComponent];
        self.attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path]
                                                                           error:error];
        self.containerStatus = ZPFileWrapperContainerStatusInitialised;
    }
    if (*error) {
        return nil;
    }
    return self;
}

+ (ZPFileWrapper*)fileWrapperWithURL:(NSURL*)url error:(NSError**)error
{
    ZPFileWrapper *result;
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory]) {
        if (isDirectory) {
            result = [[ZPDirectoryWrapper alloc] initWithURL:url error:error];
        } else {
            UIDocumentInteractionController *ic = [UIDocumentInteractionController interactionControllerWithURL:url];
            BOOL isArchiveType = NO;
            for (NSString * uti in SupportedArchiveTypes) {
                if (UTTypeConformsTo((__bridge CFStringRef)ic.UTI, (__bridge CFStringRef)uti)) {
                    isArchiveType = YES;
                    break;
                }
            }
            if (isArchiveType) {
                result = [[ZPArchiveFileWrapper alloc] initWithURL:url error:error];
            } else {
                result = [[ZPRegularFileWrapper alloc] initWithURL:url error:error];
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
    BOOL showFileExtensions = [[NSUserDefaults standardUserDefaults] boolForKey:kZPDefaultsShowFileExtensions];
    if (showFileExtensions) {
        return self.name;
    }
    return [self.name stringByDeletingPathExtension];
}

- (UIImage*)displayImage
{
    return nil;
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

- (void)setContainerStatus:(ZPFileWrapperContainerStatus)containerStatus
{
    if (containerStatus != _containerStatus) {
        _containerStatus = containerStatus;
        
        if (_containerStatus == ZPFileWrapperContainerStatusReady) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ZPFileWrapperContainerDidReloadContents
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
    // ZPFileWrapperContainerStatusReady. A pre-formatted NSNotification
    // will be sent automatically.
    //
    // On failure, it should set self.containerStatus to 
    // ZPFileWrapperContainerStatusError and send an appropriate 
    // NSNotification with error details in its payload.
    @autoreleasepool {
        NSLog(@"Error - need to override _fetchContainerContents in %@", [self class]);
    }
}

- (ZPFileWrapperContainerStatus)containerStatus
{
    return _containerStatus;
}

- (NSArray*)fileWrappers
{
    if (self.isContainer) {
        if (self.containerStatus == ZPFileWrapperContainerStatusInitialised || self.containerStatus == ZPFileWrapperContainerStatusError) {
            self.containerStatus = ZPFileWrapperContainerStatusFetchingContents;
            [self performSelectorInBackground:@selector(_fetchContainerContents) withObject:nil];
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
        self.containerStatus = ZPFileWrapperContainerStatusInitialised;
        [self performSelectorInBackground:@selector(_fetchContainerContents) withObject:nil];
    }
}

- (ZPFileWrapper*)fileWrapperAtIndex:(NSUInteger)index 
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
// Private class: ZPDirectoryWrapper
//------------------------------------------------------------

@implementation ZPDirectoryWrapper

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
            self.containerStatus = ZPFileWrapperContainerStatusError;
            [[NSNotificationCenter defaultCenter] postNotificationName:ZPFileWrapperContainerDidFailToReloadContents
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
                ZPFileWrapper *wrapper = [ZPFileWrapper fileWrapperWithURL:url error:&initError];
                if (initError) {
                    self.containerStatus = ZPFileWrapperContainerStatusError;
                    [[NSNotificationCenter defaultCenter] postNotificationName:ZPFileWrapperContainerDidFailToReloadContents
                                                                        object:self
                                                                      userInfo:[NSDictionary dictionaryWithObject:initError forKey:kErrorKey]];
                    return;
                }
                [tempArray addObject:wrapper];
                wrapper.parent = self;
            }

            // Sort by display name, case insensitive
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"displayName" 
                                                                             ascending:YES
                                                                              selector:@selector(caseInsensitiveCompare:)];
            _fileWrappers = [tempArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
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
                ZPFileWrapper * childWrapper = [_fileWrappers objectAtIndex:0];
                if (childWrapper.isDirectory) {
                    [childWrapper _fetchContainerContents];
                    _fileWrappers = childWrapper.fileWrappers;
                }
            }

            // Must set parent references AFTER we flatten nested 
            // folders, so that following the inheritance chain
            // back up still works.
            for (ZPFileWrapper* wrapper in _fileWrappers) {
                wrapper.parent = self;
            }

            self.containerStatus = ZPFileWrapperContainerStatusReady;
        }
    }
}


@end

//------------------------------------------------------------
// Private class: ZPRegularFileWrapper
//------------------------------------------------------------

@implementation ZPRegularFileWrapper

@synthesize isQueuedForImageResizing = _isQueuedForImageResizing;

#pragma mark - Private methods for preview image resizing

+ (NSOperationQueue*)_resizeQueue
{
    static NSOperationQueue * queue = nil;
    if (!queue) {
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
    }
    
    return queue;
}

- (NSString*)_displayImageCachePath
{
    NSString *itemPath = [self.url.path stringByDeletingLastPathComponent];
    NSString *filename = [[self.url.path lastPathComponent] stringByDeletingPathExtension];
    
    NSString *previewImageFilename = [NSString stringWithFormat:@".%@_preview.png", filename];
    previewImageFilename = [previewImageFilename stringByReplacingOccurrencesOfString:@"@2x" withString:@"___2x"];
    return [itemPath stringByAppendingPathComponent:previewImageFilename];
}

- (void)_generateDisplayImage
{
    @autoreleasepool {
        UIImage *result;
        
        UIImage *image = [UIImage imageWithContentsOfFile:self.url.path];
        CGFloat scale = MAX(image.size.width / kDisplayImageMaxDimension, image.size.height / kDisplayImageMaxDimension);
        CGSize newSize = image.size;
        
        newSize.height /= scale;
        newSize.width /= scale;
        
        UIGraphicsBeginImageContext(newSize);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSError *error = nil;
        [UIImagePNGRepresentation(result) writeToFile:[self _displayImageCachePath]
                                              options:NSDataWritingAtomic
                                                error:&error];
        if (error) {
            // TODO: send error notification
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:ZPFileWrapperGeneratedPreviewImageNotification
                                                                object:self];
        }
        self.isQueuedForImageResizing = NO;
    }
}

#pragma mark - Public methods

- (BOOL)isRegularFile 
{
    return YES; 
}

- (BOOL)isRetinaImageFile
{
    if (![self isImageFile])
        return NO;
    
    NSString *filenameMinusExtension = [[self.url.path lastPathComponent] stringByDeletingPathExtension];
    
    if ([filenameMinusExtension length] < 3)
        return NO;
    
    NSString *lastThreeChars = [filenameMinusExtension substringFromIndex:[filenameMinusExtension length] - 3];
    
    return [lastThreeChars isEqualToString:@"@2x"];
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

- (UIImage*)displayImage
{
    if (!self.isImageFile) {
        return nil;
    }
    
    UIImage *image = [UIImage imageWithContentsOfFile:self.url.path];
    
    BOOL needsResizing = image.size.width > kDisplayImageMaxDimension || image.size.height > kDisplayImageMaxDimension;
    
    if (!needsResizing && ![self isRetinaImageFile]) {
        return image;
    }
    
    NSString *displayImageCachePath = [self _displayImageCachePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:displayImageCachePath]) {
        return [UIImage imageWithContentsOfFile:displayImageCachePath];
    } else if (needsResizing) {
        if (!self.isQueuedForImageResizing) {
            [[ZPRegularFileWrapper _resizeQueue] addOperation:[NSBlockOperation blockOperationWithBlock:^{
                [self _generateDisplayImage];
            }]];
            self.isQueuedForImageResizing = YES;
        }
        return nil;
    } else {
        // Just copy the image to its display image cache path. Used for rendering
        // non-retina version of retina images
        
        BOOL copied = [[NSFileManager defaultManager] copyItemAtPath:self.url.path 
                                                              toPath:displayImageCachePath
                                                               error:nil];
        if (copied) {
            return [UIImage imageWithContentsOfFile:displayImageCachePath];
        } else {
            return image;
        }
    }
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
// Private class: ZPArchiveFileWrapper
//------------------------------------------------------------

@implementation ZPArchiveFileWrapper

- (BOOL)isArchive { 
    return YES; 
}

- (NSArray*)fileWrappers
{
    if (self.containerStatus == ZPFileWrapperContainerStatusReady) {
        return [_cacheDirectory fileWrappers];
    }
    return [super fileWrappers];
}

- (ZPFileWrapper*)fileWrapperAtIndex:(NSUInteger)index
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
    // Remove cache directory. Ignore errors - the OS will clean up the
    // cache directory if needed anyway
    [_cacheDirectory remove:nil];
    
    return [super remove:error];
}

- (NSString*)cachePath
{
    if (_cachePath == nil) {
        ZPAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSString *relativePath = [self.url.path stringByReplacingOccurrencesOfString:appDelegate.archiveFilesDirectory
                                                                          withString:@""
                                                                             options:0 
                                                                               range:NSMakeRange(0, appDelegate.archiveFilesDirectory.length)];
        NSString *finalDirectoryName = [relativePath stringByAppendingString:@".contents"];
        
        NSString *cacheBasePath = appDelegate.cacheDirectory;
        NSArray * pathComponents = [NSArray arrayWithObjects:
                                    cacheBasePath,
                                    finalDirectoryName,
                                    nil];
        _cachePath = [NSString pathWithComponents:pathComponents];
    }
    return _cachePath;
}

- (void)_fetchContainerContents
{
    @autoreleasepool {
        // Get the cache directory for this zip file, ensure it's
        // available and newer than the zip file it represents
        NSError * error = nil;
        NSError * underlyingError = nil;
        NSString *successMarkerPath = [self.cachePath stringByAppendingPathComponent:kSuccessfullyExtractedMarkerFile];
        
        BOOL requiresUnzipping = YES;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.cachePath]) {
            // Not a fatal error if this fails, we only want the attributes to see if we can skip 
            // unarchiving. If this fails, we'll just go ahead and unarchive anyway.
            NSDictionary *cacheAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.cachePath error:nil];
            if (cacheAttributes) {
                // We need to re-unzip if the cache directory was last modified before
                // the zip file was last modified, or if the last unzip effort didn't work
                // (signified by lack of a marker file)
                requiresUnzipping = [cacheAttributes.fileModificationDate isEarlierThanDate:_attributes.fileModificationDate]
                                 || ![[NSFileManager defaultManager] fileExistsAtPath:successMarkerPath];
            }
        }
        
        if (requiresUnzipping) {
            // Delete any current directory contents
            underlyingError = nil;
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.cachePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:self.cachePath error:&underlyingError];
                if (underlyingError) {
                    error = [NSError errorWithDomain:ZPFileWrapperErrorDomain
                                                code:ZPFileWrapperErrorFailedToDeleteCacheDirectory
                                            userInfo:[NSDictionary dictionaryWithObject:underlyingError 
                                                                                 forKey:NSUnderlyingErrorKey]];
                    
                    NSLog(@"Error on deleting existing cache directory (%@): %@, %@", self.cachePath, underlyingError, underlyingError.userInfo);
                }
            }

            if (error == nil) {
                // (Re-)create cache directory
                underlyingError = nil;
                [[NSFileManager defaultManager] createDirectoryAtPath:self.cachePath
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:&underlyingError];
                if (underlyingError) {
                    error = [NSError errorWithDomain:ZPFileWrapperErrorDomain
                                                code:ZPFileWrapperErrorFailedToCreateCacheDirectory
                                            userInfo:[NSDictionary dictionaryWithObject:underlyingError
                                                                                 forKey:NSUnderlyingErrorKey]];

                    NSLog(@"Error on creating cache directory (%@): %@, %@", self.cachePath, underlyingError, underlyingError.userInfo);
                }
                
                if (error == nil) {
                    underlyingError = nil;
                    ZPArchive *archive = [[ZPArchive alloc] initWithPath:self.url.path];
                    BOOL success = [archive extractToDirectory:self.cachePath overwrite:YES error:&underlyingError];
                    if (!success) {
                        error = [NSError errorWithDomain:ZPFileWrapperErrorDomain
                                                    code:ZPFileWrapperErrorFailedToExtractArchive
                                                userInfo:[NSDictionary dictionaryWithObject:underlyingError
                                                                                     forKey:NSUnderlyingErrorKey]];
                        
                        NSLog(@"Error on extracting archive (%@) to cache directory (%@): %@, %@", self.url.path, self.cachePath, error, [error userInfo]);
                    }
                }
            }
        }

        if (error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ZPFileWrapperContainerDidFailToReloadContents
                                                                object:self
                                                              userInfo:[NSDictionary dictionaryWithObject:error
                                                                                                   forKey:kErrorKey]];
            self.containerStatus = ZPFileWrapperContainerStatusError;
        } else {
            // All went well, so write a success marker file
            [[[NSDate date] description] writeToFile:successMarkerPath
                                          atomically:YES
                                            encoding:NSUTF8StringEncoding
                                               error:nil];
            
            _cacheDirectory = [ZPFileWrapper fileWrapperWithURL:[NSURL fileURLWithPath:self.cachePath] error:&error];
            [_cacheDirectory _fetchContainerContents];
            self.containerStatus = ZPFileWrapperContainerStatusReady;
        }
    }
}

@end
