//
//  GSZipFile.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

@interface GSZipFile : NSObject {
    @private
    unsigned long long _length;
}

@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * path;
@property (nonatomic, readonly) unsigned long long length;
@property (nonatomic, readonly) NSString * displayLength;

- (id)initWithPath:(NSString*)path;
+ (GSZipFile*)zipFileWithPath:(NSString*)path;

@end
