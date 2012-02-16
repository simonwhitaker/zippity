//
//  GSFile.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>

@interface GSFile : NSObject <QLPreviewControllerDataSource> {
@private
    unsigned long long _length;
    NSDictionary * _attributes;
}

@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * path;
@property (nonatomic, readonly) NSURL * url;
@property (nonatomic, readonly) unsigned long long length;
@property (nonatomic, readonly) NSString * displayLength;
@property (nonatomic, readonly) NSDictionary * attributes;

- (id)initWithPath:(NSString*)path;
+ (GSFile*)fileWithPath:(NSString*)path;

@end
