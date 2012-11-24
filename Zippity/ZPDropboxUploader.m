//
//  ZPDropboxUploader.m
//  Zippity
//
//  Created by Simon Whitaker on 06/11/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPDropboxUploader.h"
#import "ZPDropboxUploadJob.h"
#import <DropboxSDK/DropboxSDK.h>

NSString *const ZPDropboxUploaderDidStartUploadingFileNotification = @"ZPDropboxUploaderDidStartUploadingFileNotification";
NSString *const ZPDropboxUploaderDidFinishUploadingFileNotification = @"ZPDropboxUploaderDidFinishUploadingFileNotification";
NSString *const ZPDropboxUploaderDidGetProgressUpdateNotification = @"ZPDropboxUploaderDidGetProgressUpdateNotification";
NSString *const ZPDropboxUploaderDidFailNotification = @"ZPDropboxUploaderDidFailNotification";

NSString *const ZPDropboxUploaderFileURLKey = @"ZPDropboxUploaderFileURLKey";
NSString *const ZPDropboxUploaderProgressKey = @"ZPDropboxUploaderProgressKey";

@interface ZPDropboxUploader() <DBRestClientDelegate>

// inFlightUploadJob: the file wrapper currently being uploaded
@property (nonatomic, strong) ZPDropboxUploadJob *_inFlightUploadJob;
@property (nonatomic, strong) NSMutableArray *_uploadQueue;
@property (nonatomic, strong) DBRestClient *_dropboxClient;

- (void)_serviceQueue;

@end

@implementation ZPDropboxUploader

- (id)init
{
    self = [super init];
    if (self) {
        self._uploadQueue = [NSMutableArray array];
    }
    return self;
}

+ (ZPDropboxUploader *)sharedUploader
{
    static dispatch_once_t once;
    static ZPDropboxUploader *singleton;
    dispatch_once(&once, ^ { singleton = [[ZPDropboxUploader alloc] init]; });
    return singleton;
}

- (void)uploadFileWithURL:(NSURL *)fileURL toPath:(NSString *)destinationPath
{
    [self._uploadQueue addObject:[ZPDropboxUploadJob uploadJobWithFileURL:fileURL
                                                       andDestinationPath:destinationPath]];
    [self _serviceQueue];
}

- (void)start
{
    [self _serviceQueue];
}

- (void)_serviceQueue
{
    if ([self._uploadQueue count] > 0 && self._inFlightUploadJob == nil) {
        @synchronized(self) {
            self._inFlightUploadJob = [self._uploadQueue objectAtIndex:0];
            [self._uploadQueue removeObjectAtIndex:0];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:ZPDropboxUploaderDidStartUploadingFileNotification
                                                            object:self
                                                          userInfo:@{ZPDropboxUploaderFileURLKey: self._inFlightUploadJob.fileURL}];
        [self._dropboxClient uploadFile:self._inFlightUploadJob.fileURL.lastPathComponent
                                toPath:self._inFlightUploadJob.destinationPath
                         withParentRev:nil
                              fromPath:self._inFlightUploadJob.fileURL.path];
    }
}

- (NSUInteger)pendingUploadCount
{
    return [self._uploadQueue count];
}

- (DBRestClient *)_dropboxClient
{
    if (__dropboxClient == nil && [DBSession sharedSession] != nil) {
        __dropboxClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        __dropboxClient.delegate = self;
    }
    return __dropboxClient;
}

#pragma mark - Dropbox client delegate methods

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    [[NSNotificationCenter defaultCenter] postNotificationName:ZPDropboxUploaderDidFinishUploadingFileNotification
                                                        object:self
                                                      userInfo:@{ZPDropboxUploaderFileURLKey: self._inFlightUploadJob.fileURL}];
    self._inFlightUploadJob = nil;
    [self _serviceQueue];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:ZPDropboxUploaderDidFailNotification
                                                        object:self
                                                      userInfo:@{ZPDropboxUploaderFileURLKey: self._inFlightUploadJob.fileURL}];
    self._inFlightUploadJob = nil;
    [self _serviceQueue];
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath
{
    NSDictionary *userInfo = @{
        ZPDropboxUploaderFileURLKey: self._inFlightUploadJob.fileURL,
        ZPDropboxUploaderProgressKey: @(progress),
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:ZPDropboxUploaderDidGetProgressUpdateNotification
                                                        object:self
                                                      userInfo:userInfo];
}

@end
