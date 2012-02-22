//
//  GSFileWrapper.h
//  
//
//  Created by Simon Whitaker on 21/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kErrorKey @"error"

typedef enum {
    GSFileWrapperContainerStatusUnknown,
    GSFileWrapperContainerStatusInitialised,
    GSFileWrapperContainerStatusReady,
    GSFileWrapperContainerStatusError
} GSFileWrapperContainerStatus;

typedef enum {
    GSFileWrapperSortOrderUnspecified,
    GSFileWrapperSortOrderByName,
    GSFileWrapperSortOrderByModificationDateNewestFirst
} GSFileWrapperSortOrder;

// NSNotification names for notifications raised on completion
// of asynchronous loading of container contents
extern NSString * const GSFileWrapperContainerDidReloadContents;
extern NSString * const GSFileWrapperContainerDidFailToReloadContents;

@interface GSFileWrapper : NSObject {
    NSDictionary * _attributes;
    NSString * _name;
    NSString * _subtitle;
    NSURL * _url;
    BOOL _visited;
    
    // iVars for containers
    NSArray * _fileWrappers;
    GSFileWrapperContainerStatus _containerStatus;
    
    // TODO: move to a UIKit-aware category? Fine here for now, but
    // when we launch Zippity for OS X.... ;-)
    UIImage * _icon;
    UIDocumentInteractionController * _documentInteractionController;
}

// Initializer that determines the nature of the file 
// (whether it's a directory, etc) based on what it finds 
// when it loads the URL.
+ (GSFileWrapper*)fileWrapperWithURL:(NSURL*)url error:(NSError**)error;

- (BOOL)remove:(NSError**)error;

// Settable properties
@property (nonatomic, copy) NSString * name;
@property (nonatomic) BOOL visited;

// Materialised properties
@property (readonly) NSURL * url;
@property (readonly) NSString * subtitle;
@property (readonly) UIImage * icon;
@property (readonly) NSDictionary * attributes;
@property (readonly) UIDocumentInteractionController *documentInteractionController;

// Accessors for determining functionality of the file 
// wrapper
@property (readonly) BOOL isDirectory;
@property (readonly) BOOL isRegularFile;
@property (readonly) BOOL isArchive; // YES if the file is an archive file, e.g. a .zip, NO otherwise
@property (readonly) BOOL isContainer; // YES if the file wrapper contains other files, NO otherwise.

// Container methods: only have effect where isContainer == YES
@property (nonatomic) GSFileWrapperSortOrder sortOrder;
@property (readonly) GSFileWrapperContainerStatus containerStatus;
@property (readonly) NSArray * fileWrappers;

- (void)reloadContainerContents;
- (GSFileWrapper*)fileWrapperAtIndex:(NSUInteger)index;
- (BOOL)removeItemAtIndex:(NSUInteger)index error:(NSError**)error;

@end
