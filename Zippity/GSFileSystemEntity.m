//
//  GSFileSystemEntity.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSFileSystemEntity.h"

@implementation GSFileSystemEntity

@synthesize name=_name;
@synthesize path=_path;

#pragma mark - Object lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        _icon = nil;
        _attributes = nil;
    }
    return self;
}

- (id)initWithPath:(NSString *)path
{
    self = [self init];
    if (self) {
        self.path = path;
    }
    return self;
}

#pragma mark - Custom accessors

- (NSString *)name
{
    if (_name == nil) {
        _name = [self.path lastPathComponent];
    }
    return _name;
}

- (NSURL *)url 
{
    return [NSURL fileURLWithPath:self.path];
}

- (NSString *)subtitle
{
    return nil;
}

- (NSDictionary*)attributes
{
    if (_attributes == nil) {
        _attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil];
    }
    return _attributes;
}

- (BOOL)isVisited
{
    return YES;
}

- (BOOL)isDirectory
{
    return NO;
}

- (UIDocumentInteractionController*)documentInteractionController
{
    if (_documentInteractionController == nil) {
        _documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:self.url];
    }
    return _documentInteractionController;
}

- (UIImage*)icon
{
    if (_icon == nil) {
        if (self.documentInteractionController.icons.count > 0) {
            _icon = [self.documentInteractionController.icons objectAtIndex:0];
        }
    }
    return _icon;
}

#pragma mark - Misc methods

- (void)remove:(NSError *__autoreleasing *)error
{
    [[NSFileManager defaultManager] removeItemAtPath:self.path
                                               error:error];
}

- (void)markVisited
{
}

@end
