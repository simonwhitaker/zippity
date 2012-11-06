//
//  ZPDropboxUploader.m
//  Zippity
//
//  Created by Simon Whitaker on 06/11/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPDropboxUploader.h"
#import <DropboxSDK/DropboxSDK.h>

@interface ZPDropboxUploadJob : NSObject
@property (nonatomic, strong) ZPFileWrapper *fileWrapper;
@property (nonatomic, strong) NSString *destinationPath;
+ (ZPDropboxUploadJob *)uploadJobWithFileWrapper:(ZPFileWrapper *)fileWrapper andDestinationPath:(NSString *)destinationPath;
@end

@implementation ZPDropboxUploadJob
+ (ZPDropboxUploadJob *)uploadJobWithFileWrapper:(ZPFileWrapper *)fileWrapper andDestinationPath:(NSString *)destinationPath
{
    ZPDropboxUploadJob *job = [[ZPDropboxUploadJob alloc] init];
    job.fileWrapper = fileWrapper;
    job.destinationPath = destinationPath;
    return job;
}
@end

@interface ZPDropboxUploader() <DBRestClientDelegate>

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

- (void)uploadFileWrapper:(ZPFileWrapper *)fileWrapper toPath:(NSString *)destinationPath
{
    [self.uploadQueue addObject:[ZPDropboxUploadJob uploadJobWithFileWrapper:fileWrapper
                                                          andDestinationPath:destinationPath]];
    [self serviceQueue];
}

- (void)serviceQueue
{
    if ([self.uploadQueue count] > 0) {
        ZPDropboxUploadJob *job;
        @synchronized(self) {
            job = [self.uploadQueue objectAtIndex:0];
            [self.uploadQueue removeObjectAtIndex:0];
        }
        [self.dropboxClient uploadFile:job.fileWrapper.url.lastPathComponent
                                toPath:job.destinationPath
                         withParentRev:nil
                              fromPath:job.fileWrapper.url.path];
    }
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
    [self serviceQueue];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"File upload failed with error - %@", error);
    [self serviceQueue];
}


@end
