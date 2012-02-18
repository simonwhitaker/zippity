//
//  GSFileSystemEntity.h
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GSFileSystemEntity : NSObject {
@private
    NSDictionary * _attributes;
    UIImage * _icon;
    UIDocumentInteractionController * _documentInteractionController;
}

@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * path;
@property (nonatomic, readonly) NSURL * url;
@property (nonatomic, readonly) NSString * subtitle;
@property (nonatomic, readonly) NSDictionary * attributes;

@property (nonatomic, readonly) UIDocumentInteractionController *documentInteractionController;
@property (nonatomic, readonly) UIImage * icon;

- (id)initWithPath:(NSString*)path;
- (BOOL)isVisited;
- (void)markVisited;
- (void)remove:(NSError *__autoreleasing *)error;

@end
