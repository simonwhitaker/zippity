//
//  ZPDropboxUploader.h
//  Zippity
//
//  Created by Simon Whitaker on 06/11/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZPDropboxUploader : NSObject

extern NSString *const ZPDropboxUploaderDidStartUploadingFileNotification;
extern NSString *const ZPDropboxUploaderDidFinishUploadingFileNotification;
extern NSString *const ZPDropboxUploaderDidGetProgressUpdateNotification;
extern NSString *const ZPDropboxUploaderDidFailNotification;

// UserInfo dictionary keys
extern NSString *const ZPDropboxUploaderFileURLKey;
extern NSString *const ZPDropboxUploaderProgressKey;

+ (ZPDropboxUploader*)sharedUploader;
- (void)uploadFileWithURL:(NSURL *)fileURL toPath:(NSString*)destinationPath;

/* Uploads are processed one at a time. If you call uploadFileWithURL:toPath: while an upload's already in progress the new upload will be queued. pendingUploadCount returns the number of uploads currently in the queue pending processing. */
- (NSUInteger)pendingUploadCount;

@end
