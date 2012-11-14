//
//  ZPDropboxUploader.h
//  Zippity
//
//  Created by Simon Whitaker on 06/11/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZPFileWrapper.h"

@interface ZPDropboxUploader : NSObject

extern NSString *const ZPDropboxUploaderDidStartUploadingFileNotification;
extern NSString *const ZPDropboxUploaderDidFinishUploadingFileNotification;
extern NSString *const ZPDropboxUploaderDidGetProgressUpdateNotification;
extern NSString *const ZPDropboxUploaderDidFailNotification;

// UserInfo dictionary keys
extern NSString *const ZPDropboxUploaderFileWrapperKey;
extern NSString *const ZPDropboxUploaderProgressKey;

+ (ZPDropboxUploader*)sharedUploader;
- (void)uploadFileWrapper:(ZPFileWrapper*)fileWrapper toPath:(NSString*)destinationPath;
- (NSUInteger)queueSize;
- (void)start;

@end
