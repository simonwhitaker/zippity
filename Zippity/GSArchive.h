//
//  GSArchive.h
//  Zippity
//
//  Created by Simon Whitaker on 01/03/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GSArchive : NSObject

@property (nonatomic, retain) NSString * path;

- (id)initWithPath:(NSString*)path;
- (BOOL)extractToDirectory:(NSString*)directoryPath overwrite:(BOOL)shouldOverwrite error:(NSError**)error;

@end
