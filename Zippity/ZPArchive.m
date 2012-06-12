//
//  GSArchive.m
//  Zippity
//
//  Created by Simon Whitaker on 01/03/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPArchive.h"
#import "libarchive/archive.h"
#import "libarchive/archive_entry.h"

static NSDictionary * errorInfoForArchive(struct archive *a) {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    [info setObject:[NSString stringWithCString:archive_error_string(a) encoding:NSUTF8StringEncoding]
             forKey:kGSArchiveLowLevelErrorStringKey];
    [info setObject:[NSNumber numberWithInt:archive_errno(a)]
             forKey:kGSArchiveLowLevelErrorCodeKey];
    return [NSDictionary dictionaryWithDictionary:info];
}


static int copy_data(struct archive *ar, struct archive *aw) {
    int r;
    const void *buff;
    size_t size;
    off_t offset;
    
    for (;;) {
        r = archive_read_data_block(ar, &buff, &size, &offset);
        if (r == ARCHIVE_EOF) {
            return ARCHIVE_OK;
        }
        if (r != ARCHIVE_OK) {
            return r;
        }
        r = archive_write_data_block(aw, buff, size, offset);
        if (r != ARCHIVE_OK) {
            NSLog(@"Error on writing archive data block: %s", archive_error_string(aw));
            return r;
        }
    }
    return 0;
}

@interface ZPArchive()

- (NSString*)filenameForPseudoArchiveContents;

@end

@implementation ZPArchive

@synthesize path=_path;

- (id)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        self.path = path;
    }
    return self;
}

- (BOOL)isPseudoArchive
{
    if (_isPseudoArchiveObj == nil) {
        BOOL result = NO;
        NSString *filename = [[self.path lastPathComponent] lowercaseString];
        
        static NSRegularExpression *PlainGzRegex;
        static NSRegularExpression *PlainBz2Regex;
        
        if (PlainGzRegex == nil) {
            // Construct a regex looking for .gz with a negative look-behind
            // assertion to exclude .tar.gz files
            PlainGzRegex = [NSRegularExpression regularExpressionWithPattern:@"(?<!\\.tar)\\.gz$"
                                                                     options:NSRegularExpressionCaseInsensitive
                                                                       error:nil];
        }
        
        if (PlainBz2Regex == nil) {
            // Construct a regex looking for .bz / .bz2 with a negative look-behind
            // assertion to exclude .tar.bz2 / .tar.bz files
            PlainBz2Regex = [NSRegularExpression regularExpressionWithPattern:@"(?<!\\.tar)\\.bz2?$"
                                                                      options:NSRegularExpressionCaseInsensitive
                                                                        error:nil];
        }
        
        NSRange r = NSMakeRange(0, [filename length]);
        if (PlainGzRegex && [PlainGzRegex numberOfMatchesInString:filename options:0 range:r] > 0) {
            result = YES;
        } else if (PlainBz2Regex && [PlainBz2Regex numberOfMatchesInString:filename options:0 range:r] > 0) {
            result = YES;
        }
        _isPseudoArchiveObj = [NSNumber numberWithBool:result];
    }
    return [_isPseudoArchiveObj boolValue];
}

- (NSString*)filenameForPseudoArchiveContents
{
    // For now our only valid cases are somefile.gz and somefile.bz[2]. In
    // either case we can get the filename by just stripping off the
    // file extension.
    return [[self.path lastPathComponent] stringByDeletingPathExtension];
}

- (BOOL)extractToDirectory:(NSString *)directoryPath overwrite:(BOOL)shouldOverwrite error:(NSError *__autoreleasing *)error
{
    struct archive *a;
    struct archive *ext;
    struct archive_entry *entry;
    
    NSStringEncoding filenameStringEncoding = 0;
    
    const char * filename = [self.path UTF8String];
        
    int flags;
    int r;
    
    flags = ARCHIVE_EXTRACT_TIME;

    a = archive_read_new();
    archive_read_support_format_all(a);
    archive_read_support_compression_all(a);
    
    // Support files that aren't actually "archives", such as
    // plain .gz and .bz2 files
    archive_read_support_format_raw(a);
    
    ext = archive_write_disk_new();
    archive_write_disk_set_options(ext, flags);
    archive_write_disk_set_standard_lookup(ext);
    
    r = archive_read_open_filename(a, filename, 10240);
    if (r != ARCHIVE_OK) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:kGSArchiveErrorDomain
                                                code:GSArchiveFileReadError
                                            userInfo:errorInfoForArchive(a)];
        }
        return NO;
    }
    
    for (;;) {
        r = archive_read_next_header(a, &entry);
        
        if (r == ARCHIVE_EOF) {
            break;
        }
        if (r < ARCHIVE_OK) {
            if (error) {
                *error = [[NSError alloc] initWithDomain:kGSArchiveErrorDomain 
                                                    code:GSArchiveEntryReadError
                                                userInfo:errorInfoForArchive(a)];
            }
            return NO;
        }
        
        const char * cPath = archive_entry_pathname(entry);
        
        NSString *path = nil;
        NSNumber * encodingObj = [[NSUserDefaults standardUserDefaults] objectForKey:kZPDefaultsLastChosenCharacterEncoding];
        
        if ([self isPseudoArchive]) {
            path = [self filenameForPseudoArchiveContents];
            // Set standard permissions, otherwise it gets
            // perms of 0000.
            archive_entry_set_perm(entry, S_IRWXU);
        } else {
            // Attempt to interpret the filename as a UTF-8 string
            path = [NSString stringWithCString:cPath encoding:NSUTF8StringEncoding];
            
            // Didn't work? If we have an alternative that we've determined previously 
            // for this archive, use that instead.
            if (!path && filenameStringEncoding) {
                path = [NSString stringWithCString:cPath encoding:filenameStringEncoding];
            }
            
            // Still no path? See if we've got a user-chosen one.
            if (!path) {
                if (encodingObj) {
                    NSStringEncoding encoding = [encodingObj unsignedLongValue];
                    path = [NSString stringWithCString:cPath encoding:encoding];
                }
            }
            
            // Still no path? Throw an error and let the UI decide what to do.
            if (!path) {
                NSData * pathData = [NSData dataWithBytes:cPath length:strlen(cPath)];
                *error = [[NSError alloc] initWithDomain:kGSArchiveErrorDomain
                                                    code:GSArchiveEntryFilenameEncodingUnknownError
                                                userInfo:[NSDictionary dictionaryWithObject:pathData forKey:kGSArchiveEntryFilenameCStringAsNSData]];
                return NO;
            }
        }
        
        if (!path) {
            *error = [[NSError alloc] initWithDomain:kGSArchiveErrorDomain
                                                code:GSArchiveEntryReadError
                                            userInfo:nil];
            return NO;
        }
        

        NSString *fullPath = [directoryPath stringByAppendingPathComponent:path];
        const char * cFullPath = [fullPath UTF8String];
        archive_entry_set_pathname(entry, cFullPath);
        
        r = archive_write_header(ext, entry);
        if (r != ARCHIVE_OK) {
            if (error) {
                *error = [[NSError alloc] initWithDomain:kGSArchiveErrorDomain 
                                                    code:GSArchiveEntryWriteError
                                                userInfo:errorInfoForArchive(a)];
            }
            return NO;
        } else if (archive_entry_size(entry) > 0 || !archive_entry_size_is_set(entry)) {
            r = copy_data(a, ext);
            if (r != ARCHIVE_OK) {
                if (error) {
                    *error = [[NSError alloc] initWithDomain:kGSArchiveErrorDomain 
                                                        code:GSArchiveEntryWriteError
                                                    userInfo:errorInfoForArchive(a)];
                }
                return NO;
            }
        }
        
        r = archive_write_finish_entry(ext);
        if (r != ARCHIVE_OK) {
            if (error) {
                *error = [[NSError alloc] initWithDomain:kGSArchiveErrorDomain
                                                    code:GSArchiveEntryWriteError
                                                userInfo:errorInfoForArchive(a)];
            }
            return NO;
        }
    }
    
    archive_read_close(a);
    archive_read_finish(a);
    archive_write_close(ext);
    archive_write_finish(ext);
    return YES;
}

@end
