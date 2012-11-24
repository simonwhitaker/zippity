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
    // default returns nil. subclass may override to return custom activity type that is reported to completion handler
    return [ZPDropboxActivity activityTypeString];
}

- (NSString *)activityTitle {
    // default returns nil. subclass must override and must return non-nil value
    return @"Dropbox";
}
- (UIImage *)activityImage {
    // default returns nil. subclass must override and must return non-nil value
    return [UIImage imageNamed:@"dropbox-activity-icon"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    // override this to return availability of activity based on items. default returns NO
    for (id obj in activityItems) {
        if ([obj isKindOfClass:[NSURL class]] || [obj isKindOfClass:[UIImage class]]) {
            return YES;
        }
    }
    return NO;
};

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    // override to extract items and set up your HI. default does nothing
    self.activityItems = activityItems;
}

- (UIViewController *)activityViewController {
    // return non-nil to have vC presented modally. call activityDidFinish at end. default returns nil
    ZPDropboxDestinationSelectionViewController *vc = [[ZPDropboxDestinationSelectionViewController alloc] initWithStyle:UITableViewStylePlain];
    vc.delegate = self;

    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    return nc;
}

//- (void)performActivity {
//    // if no view controller, this method is called. call activityDidFinish when done. default calls [self activityDidFinish:NO]
//}

//- (void)activityDidFinish:(BOOL)completed {
//    // activity must call this when activity is finished. can be called on any thread
//}

#pragma mark - ZPDropboxDestinationSelectionViewController delegate methods

- (void)dropboxDestinationSelectionViewController:(ZPDropboxDestinationSelectionViewController *)viewController didSelectDestinationPath:(NSString *)destinationPath
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
