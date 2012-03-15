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

- (BOOL)extractToDirectory:(NSString *)directoryPath overwrite:(BOOL)shouldOverwrite error:(NSError *__autoreleasing *)error
{
    struct archive *a;
    struct archive *ext;
    struct archive_entry *entry;
    
    const char * filename = [self.path UTF8String];
    
    int flags;
    int r;
    
    flags = ARCHIVE_EXTRACT_TIME;

    a = archive_read_new();
    archive_read_support_format_all(a);
    archive_read_support_compression_all(a);
    
    ext = archive_write_disk_new();
    archive_write_disk_set_options(ext, flags);
    archive_write_disk_set_standard_lookup(ext);
    
    r = archive_read_open_filename(a, filename, 10240);
    if (r != ARCHIVE_OK) {
        *error = [[NSError alloc] initWithDomain:kGSArchiveErrorDomain
                                            code:GSArchiveFileReadError
                                        userInfo:errorInfoForArchive(a)];
        return NO;
    }
    
    for (;;) {
        r = archive_read_next_header(a, &entry);
        
        if (r == ARCHIVE_EOF) {
            break;
        }
        if (r < ARCHIVE_OK) {
            *error = [[NSError alloc] initWithDomain:kGSArchiveErrorDomain 
                                                code:GSArchiveEntryReadError
                                            userInfo:errorInfoForArchive(a)];
            return NO;
        }
        
        const char * cPath = archive_entry_pathname(entry);
        NSString *path = [NSString stringWithCString:cPath encoding:NSUTF8StringEncoding];
        NSString *fullPath = [directoryPath stringByAppendingPathComponent:path];
        const char * cFullPath = [fullPath UTF8String];
        archive_entry_set_pathname(entry, cFullPath);
        
        r = archive_write_header(ext, entry);
        if (r != ARCHIVE_OK) {
            *error = [[NSError alloc] initWithDomain:kGSArchiveErrorDomain 
                                                code:GSArchiveEntryWriteError
                                            userInfo:errorInfoForArchive(a)];
            return NO;
        } else if (archive_entry_size(entry) > 0 || !archive_entry_size_is_set(entry)) {
            r = copy_data(a, ext);
            if (r != ARCHIVE_OK) {
                *error = [[NSError alloc] initWithDomain:kGSArchiveErrorDomain 
                                                    code:GSArchiveEntryWriteError
                                                userInfo:errorInfoForArchive(a)];
                return NO;
            }
        }
        
        r = archive_write_finish_entry(ext);
        if (r != ARCHIVE_OK) {
            *error = [[NSError alloc] initWithDomain:kGSArchiveErrorDomain
                                                code:GSArchiveEntryWriteError
                                            userInfo:errorInfoForArchive(a)];
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
