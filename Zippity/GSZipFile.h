//
//  GSZipFile.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//
#import "GSFile.h"

#define kZipFileStatusKey @"status"

typedef enum {
    GSZipFileUnzipStatusUnknown,
    GSZipFileUnzipStatusInitialized,
    GSZipFileUnzipStatusUnzipping,
    GSZipFileUnzipStatusComplete,
    GSZipFileUnzipStatusError
} GSZipFileUnzipStatus;

@interface GSZipFile : GSFile {
@private
    NSArray * _contents;
    GSZipFileUnzipStatus _status;
}

@property (nonatomic, readonly) GSZipFileUnzipStatus status;
@property (nonatomic, readonly) NSArray * contents;

+ (GSZipFile*)zipFileWithPath:(NSString*)path;

extern NSString * const GSZipFileDidUpdateUnzipStatus;

@end
