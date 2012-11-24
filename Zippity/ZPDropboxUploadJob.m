//
//  ZPDropboxUploadJob.m
//  Zippity
//
//  Created by Simon Whitaker on 24/11/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPDropboxUploadJob.h"

@implementation ZPDropboxUploadJob

+ (ZPDropboxUploadJob *)uploadJobWithFileURL:(NSURL *)fileURL andDestinationPath:(NSString *)destinationPath
{
    ZPDropboxUploadJob *job = [[ZPDropboxUploadJob alloc] init];
    job.fileURL = fileURL;
    job.destinationPath = destinationPath;
    return job;
}

@end
