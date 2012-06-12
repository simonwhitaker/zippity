//
//  GSArchive.h
//  Zippity
//
//  Created by Simon Whitaker on 01/03/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kGSArchiveErrorDomain @"GSArchive"
#define kGSArchiveLowLevelErrorCodeKey @"LowLevelErrorCode"
#define kGSArchiveLowLevelErrorStringKey @"LowLevelErrorString"

#define kGSArchiveEntryFilenameCStringAsNSData @"ArchiveEntryFilenameCString"

enum {
    GSArchiveFileReadError = 1,
    GSArchiveEntryReadError,
    GSArchiveEntryWriteError,
    GSArchiveEntryFilenameEncodingUnknownError,
};

@interface ZPArchive : NSObject {
    __strong NSNumber * _isPseudoArchiveObj;
}

@property (nonatomic, retain) NSString * path;

// Files such as foo.txt.gz or foo.txt.bz2 aren't real archives; 
// the compressed file doesn't contain any metadata about e.g.
// the filename of the file it contains. (In the case of .gz and
// .bz2, command line tools infer the filename of the uncompressed
// file from the filename of the compressed file.)
//
// We'll call these files "pseudo-archives". libarchive can still 
// handle them (provided we've called archive_read_support_format_raw())
// but we need to do a bit of additional work - essentially just
// inferring the filename for the unpacked file.
@property (readonly) BOOL isPseudoArchive;

- (id)initWithPath:(NSString*)path;
- (BOOL)extractToDirectory:(NSString*)directoryPath overwrite:(BOOL)shouldOverwrite error:(NSError**)error;

@end
