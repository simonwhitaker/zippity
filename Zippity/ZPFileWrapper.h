//
//  ZPFileWrapper.h
//  
//
//  Created by Simon Whitaker on 21/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kErrorKey @"error"

typedef enum {
    ZPFileWrapperContainerStatusUnknown,
    ZPFileWrapperContainerStatusInitialised,
    ZPFileWrapperContainerStatusReady,
    ZPFileWrapperContainerStatusError
} ZPFileWrapperContainerStatus;

// NSNotification names for notifications raised on completion
// of asynchronous loading of container contents
extern NSString * const ZPFileWrapperContainerDidReloadContents;
extern NSString * const ZPFileWrapperContainerDidFailToReloadContents;

@interface ZPFileWrapper : NSObject {
    NSDictionary * _attributes;
    NSString * _name;
    NSString * _humanFileSize;
    NSURL * _url;
    
    // iVars for containers
    NSArray * _fileWrappers;
    ZPFileWrapperContainerStatus _containerStatus;
    
    // TODO: move to a UIKit-aware category? Fine here for now, but
    // when we launch Zippity for OS X.... ;-)
    UIImage * _icon;
    UIDocumentInteractionController * _documentInteractionController;
}

// Initializer that determines the nature of the file 
// (whether it's a directory, etc) based on what it finds 
// when it loads the URL.
+ (ZPFileWrapper*)fileWrapperWithURL:(NSURL*)url error:(NSError**)error;

- (BOOL)remove:(NSError**)error;

// Settable properties
@property (nonatomic, copy) NSString * name;
@property (nonatomic, assign) ZPFileWrapper * parent;

// Materialised properties
@property (readonly) NSURL * url;
@property (readonly) NSString * displayName;
@property (readonly) UIImage * displayImage; // nil if isImageFile is NO, else an image resized if necessary to be suitable for preview
@property (readonly) NSString * humanFileSize;

@property (readonly) UIImage * icon;
@property (readonly) NSDictionary * attributes;
@property (readonly) UIDocumentInteractionController *documentInteractionController;

// Accessors for determining functionality of the file 
// wrapper
@property (readonly) BOOL isDirectory;
@property (readonly) BOOL isRegularFile;
@property (readonly) BOOL isArchive; // YES if the file is an archive file, e.g. a .zip, NO otherwise
@property (readonly) BOOL isContainer; // YES if the file wrapper contains other files, NO otherwise.
@property (readonly) BOOL isImageFile; // YES if the file is an image that can be displayed in a UIImage

// Container methods: only have effect where isContainer == YES
@property (readonly) ZPFileWrapperContainerStatus containerStatus;
@property (readonly) NSArray * fileWrappers;
@property (readonly) NSArray * imageFileWrappers;

- (void)reloadContainerContents;
- (ZPFileWrapper*)fileWrapperAtIndex:(NSUInteger)index;
- (BOOL)removeItemAtIndex:(NSUInteger)index error:(NSError**)error;

extern NSString * const ZPFileWrapperGeneratedPreviewImageNotification;

@end
