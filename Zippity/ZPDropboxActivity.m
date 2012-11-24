//
//  ZPDropboxActivity.m
//  Zippity
//
//  Created by Simon Whitaker on 19/11/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPDropboxActivity.h"
#import "ZPDropboxDestinationSelectionViewController.h"
#import "ZPDropboxUploader.h"
#import <DropboxSDK/DropboxSDK.h>

#import "ZPAboutViewController.h"

@interface ZPDropboxActivity() <ZPDropboxDestinationSelectionViewControllerDelegate>

@property (nonatomic, copy) NSArray *activityItems;
@property (nonatomic, retain) ZPDropboxDestinationSelectionViewController *dropboxDestinationViewController;
@end

@implementation ZPDropboxActivity

+ (NSString *)activityTypeString
{
    return @"uk.co.goosoftware.DropboxActivity";
}

- (NSString *)activityType {
    return [ZPDropboxActivity activityTypeString];
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Dropbox", @"Name of the service at www.dropbox.com");
}
- (UIImage *)activityImage {
    return [UIImage imageNamed:@"dropbox-activity-icon"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id obj in activityItems) {
        if ([obj isKindOfClass:[NSURL class]] || [obj isKindOfClass:[UIImage class]]) {
            return YES;
        }
    }
    return NO;
};

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    self.activityItems = activityItems;
}

- (UIViewController *)activityViewController {
    ZPDropboxDestinationSelectionViewController *vc = [[ZPDropboxDestinationSelectionViewController alloc] initWithStyle:UITableViewStylePlain];
    vc.delegate = self;

    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    return nc;
}

#pragma mark - ZPDropboxDestinationSelectionViewController delegate methods

- (void)dropboxDestinationSelectionViewController:(ZPDropboxDestinationSelectionViewController *)viewController
                         didSelectDestinationPath:(NSString *)destinationPath
{
    for (NSURL *fileURL in self.activityItems) {
        [[ZPDropboxUploader sharedUploader] uploadFileWithURL:fileURL toPath:destinationPath];
    }
    self.activityItems = nil;
    [self activityDidFinish:YES];
}

- (void)dropboxDestinationSelectionViewControllerDidCancel:(ZPDropboxDestinationSelectionViewController *)viewController
{
    self.activityItems = nil;
    [self activityDidFinish:NO];
}

@end
