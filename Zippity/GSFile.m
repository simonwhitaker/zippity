//
//  GSFile.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSFile.h"

@implementation GSFile

- (id)init
{
    self = [super init];
    if (self) {
        _size = 0;
        _subtitle = nil;
    }
    return self;
}

+ (GSFile*)fileWithPath:(NSString *)path
{
    return [[GSFile alloc] initWithPath:path];
}

- (unsigned long long)size
{    
    if (_size == 0) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError * error = nil;
        NSDictionary *d = [fm attributesOfItemAtPath:self.path
                                               error:&error];
        if (error) {
            NSLog(@"Error on getting file attributes: %@, %@", error, error.userInfo);
        } else {
            _size = [d fileSize];
        }
    }
    return _size;
}

// Change to 1000 to show "marketing bytes"
#define BYTES_IN_DISPLAY_KILOBYTE 1024.0f

- (NSString*)subtitle
{
    if (_subtitle == nil) {
        static NSDateFormatter *DateFormatter = nil;
        if (DateFormatter == nil) {
            DateFormatter = [[NSDateFormatter alloc] init];
            DateFormatter.timeStyle = NSDateFormatterNoStyle;
            DateFormatter.dateStyle = NSDateFormatterMediumStyle;
        }
        NSString *lastModifiedString = [DateFormatter stringFromDate:self.attributes.fileModificationDate];
        
        static NSArray *SizeSuffixes = nil;
        if (SizeSuffixes == nil) {
            SizeSuffixes = [NSArray arrayWithObjects: @"KB", @"MB", @"GB", nil];
        }
        NSString * sizeString = [NSString stringWithFormat:@"%llu bytes", self.size];

        CGFloat sizef = (CGFloat)self.size;
        for (NSString * suffix in SizeSuffixes) {
            if (sizef > BYTES_IN_DISPLAY_KILOBYTE) {
                sizef /= BYTES_IN_DISPLAY_KILOBYTE;
                sizeString = [NSString stringWithFormat:@"%.0f %@", sizef, suffix];
            } else {
                break;
            }
        }
        
        _subtitle = [NSString stringWithFormat:@"%@, last modified %@", sizeString, lastModifiedString];
    }
    return _subtitle;
}

@end
