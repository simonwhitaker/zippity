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
@property (nonatomic, strong) ZPDropboxUploadJob *inFlightUploadJob;

@property (nonatomic, strong) NSMutableArray *uploadQueue;
@property (nonatomic, strong) DBRestClient *dropboxClient;

- (void)serviceQueue;

@end

@implementation ZPDropboxUploader

- (id)init
{
    self = [super init];
    if (self) {
        self.uploadQueue = [NSMutableArray array];
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
    [self.uploadQueue addObject:[ZPDropboxUploadJob uploadJobWithFileURL:fileURL
                                                          andDestinationPath:destinationPath]];
}

- (void)start
{
    [self serviceQueue];
}

- (void)serviceQueue
{
    if ([self.uploadQueue count] > 0 && self.inFlightUploadJob == nil) {
        @synchronized(self) {
            self.inFlightUploadJob = [self.uploadQueue objectAtIndex:0];
            [self.uploadQueue removeObjectAtIndex:0];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:ZPDropboxUploaderDidStartUploadingFileNotification
                                                            object:self
                                                          userInfo:@{ZPDropboxUploaderFileURLKey: self.inFlightUploadJob.fileURL}];
        [self.dropboxClient uploadFile:self.inFlightUploadJob.fileURL.lastPathComponent
                                toPath:self.inFlightUploadJob.destinationPath
                         withParentRev:nil
                              fromPath:self.inFlightUploadJob.fileURL.path];
    }
}

- (NSUInteger)pendingUploadCount
{
    return [self.uploadQueue count];
}

- (DBRestClient *)dropboxClient
{
    if (_dropboxClient == nil && [DBSession sharedSession] != nil) {
        _dropboxClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _dropboxClient.delegate = self;
    }
    return _dropboxClient;
}

#pragma mark - Dropbox client delegate methods

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
    [[NSNotificationCenter defaultCenter] postNotificationName:ZPDropboxUploaderDidFinishUploadingFileNotification
                                                        object:self
                                                      userInfo:@{ZPDropboxUploaderFileURLKey: self.inFlightUploadJob.fileURL}];
    self.inFlightUploadJob = nil;
    [self serviceQueue];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"File upload failed with error - %@", error);
    [[NSNotificationCenter defaultCenter] postNotificationName:ZPDropboxUploaderDidFailNotification
                                                        object:self
                                                      userInfo:@{ZPDropboxUploaderFileURLKey: self.inFlightUploadJob.fileURL}];
    self.inFlightUploadJob = nil;
    [self serviceQueue];
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath
{
    NSDictionary *userInfo = @{
        ZPDropboxUploaderFileURLKey: self.inFlightUploadJob.fileURL,
        ZPDropboxUploaderProgressKey: @(progress),
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:ZPDropboxUploaderDidGetProgressUpdateNotification
                                                        object:self
                                                      userInfo:userInfo];
}

@end
