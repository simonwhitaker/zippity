//
//  GSAppDelegate.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "ZPAppDelegate.h"
#import "TestFlight.h"
#import "ZPEmptyViewController.h"
#import "ZPImagePreviewController.h"
#import "ZPPreviewController.h"
#import <DropboxSDK/DropboxSDK.h>
#import "GSDropboxUploader.h"

#define kMaxSuffixesToTry 100

@interface ZPAppDelegate()

- (NSString*)documentsDirectory;
- (void)handleDropboxUploadStartedNotification:(NSNotification *)notification;
- (void)handleDropboxUploadProgressNotification:(NSNotification *)notification;
- (void)updateDropboxUploadStatus;

@end

@implementation ZPAppDelegate

@synthesize window = _window;
@synthesize rootListViewController = _rootListViewController;
@synthesize masterViewNavigationController = _navigationController;
@synthesize splitViewController = _splitViewController;
@synthesize detailViewNavigationController = _detailViewNavigationController;
@synthesize masterPopoverController = _masterPopoverController;
@synthesize masterPopoverButton = _masterPopoverButton;

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    [appDefaults setObject:[NSNumber numberWithBool:YES] forKey:kZPDefaultsFirstLaunchKey];
    [appDefaults setObject:[NSNumber numberWithBool:NO] forKey:kZPDefaultsShowFileExtensions];
    [defaults registerDefaults:appDefaults];
}

- (void)cleanInboxDirectory 
{
    NSString *inboxPath = [self.documentsDirectory stringByAppendingPathComponent:@"Inbox"];
    for (NSString *filename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:inboxPath error:nil]) {
        NSError *error = nil;
        NSString *filePath = [inboxPath stringByAppendingPathComponent:filename];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"Error deleting %@: %@, %@", filePath, error, error.userInfo);
        }
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TestFlight takeOff:@"c9a1cdc85d251c1574f49750c3db2a52_NzcyMzIwMTEtMDktMTYgMDU6MTI6MTkuOTU1OTM3"];

#if defined (DEBUG) || defined (ADHOC)
    /*
     Disable deprecated-declarations warning.
     See http://clang.llvm.org/docs/UsersManual.html#diagnostics_pragmas
     
     Basic workflow:
     
        1. push current warnings onto stack
        2. ignore warning we know will get thrown
        3. do dodgy thing that causes warning
        4. pop warnings - go back to what we had before we started dicking around with them
     
     */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#pragma clang diagnostic pop
#endif

    /* Initialise Dropbox SDK */
    DBSession *dbSession = [[DBSession alloc] initWithAppKey:@"3rrp23i61km7y4p"
                                                   appSecret:@"cz04gux12ldrfua"
                                                        root:kDBRootDropbox];
    [DBSession setSharedSession:dbSession];

    // NOTE: for testing only, don't check in!
    //[[DBSession sharedSession] unlinkAll];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    // First run: add a sample zip file
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kZPDefaultsFirstLaunchKey]) {
        NSString *sampleZipFile = [[NSBundle mainBundle] pathForResource:@"Welcome to Zippity.zip" ofType:nil];
        NSString *sampleTargetPath = [self.archiveFilesDirectory stringByAppendingPathComponent:[sampleZipFile lastPathComponent]];
        [[NSFileManager defaultManager] removeItemAtPath:sampleTargetPath error:nil];
        [[NSFileManager defaultManager] copyItemAtPath:sampleZipFile toPath:sampleTargetPath error:nil];
        
        [defaults setBool:NO forKey:kZPDefaultsFirstLaunchKey];
        [defaults synchronize];
    }
    
    // Create a ZPFileWrapper object to act as the data source for the
    // root folder's view controller. Set its name with the string I
    // want to appear in the NavigationItem's title.
    NSError *error = nil;
    ZPFileWrapper * rootFileWrapper = [ZPFileWrapper fileWrapperWithURL:[NSURL fileURLWithPath:self.archiveFilesDirectory] error:&error];
    if (error) {
        // TODO: handle error
    }
    rootFileWrapper.name = @"Zippity";
    self.rootListViewController = [[ZPFileContainerListViewController alloc] initWithContainer:rootFileWrapper];
    self.rootListViewController.isRoot = YES;
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:self.rootListViewController];
    self.masterViewNavigationController = nc;
    nc.delegate = self;
    GSStatusBarViewController *statusBarViewController = [[GSStatusBarViewController alloc] initWithContentViewController:nc];

    if (isIpad) {
        ZPEmptyViewController * evc = [[ZPEmptyViewController alloc] init];
        self.detailViewNavigationController = [[UINavigationController alloc] initWithRootViewController:evc];
        
        [self applyTintToDetailViewNavigationController];
        
        self.splitViewController = [[UISplitViewController alloc] init];
        self.splitViewController.delegate = self;
        self.splitViewController.viewControllers = @[statusBarViewController, self.detailViewNavigationController];
        self.window.rootViewController = self.splitViewController;
    } else {
        statusBarViewController.wantsFullScreenLayout = YES;
        self.window.rootViewController = statusBarViewController;
    }
    // Store a weak ref to the status bar controller
    self.statusBarViewController = statusBarViewController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{    
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    // Delete any temporary files that have been left in the Inbox directory
    [self cleanInboxDirectory];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Cancel any pending Dropbox uploads
    [[GSDropboxUploader sharedUploader] cancelAll];

    // Hide the status bar
    [self.statusBarViewController dismissAnimated:NO];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDropboxUploadStartedNotification:) name:GSDropboxUploaderDidStartUploadingFileNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDropboxUploadStatus) name:GSDropboxUploaderDidFinishUploadingFileNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDropboxUploadStatus) name:GSDropboxUploaderDidFailNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDropboxUploadProgressNotification:) name:GSDropboxUploaderDidGetProgressUpdateNotification object:nil];
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    BOOL shoudClearCache = [defaults boolForKey:kZPDefaultsClearCacheKey];
    
    if (shoudClearCache) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;
        NSArray *cacheContents = [fm contentsOfDirectoryAtPath:self.cacheDirectory error:&error];
        if (error) {
            
        } else {
            for (NSString *filename in cacheContents) {
                NSString *path = [self.cacheDirectory stringByAppendingPathComponent:filename];
                [fm removeItemAtPath:path error:&error];
                if (error) {
                    NSLog(@"Error on deleting %@: %@, %@", path, error, error.userInfo);
                }
            }
        }
    }
    [defaults setBool:NO forKey:kZPDefaultsClearCacheKey];
    [defaults synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked to Dropbox successfully");
        } else {
            NSLog(@"App not linked to Dropbox!");
        }
        return YES;
    }
    // Dismiss the info view if it's visible
    [self.masterViewNavigationController dismissModalViewControllerAnimated:NO];
    
    NSString *incomingPath = [url path];
    NSString *filename = [incomingPath lastPathComponent];
    NSString *targetPath = [self.archiveFilesDirectory stringByAppendingPathComponent:filename];
    
    NSError *error = nil;
    
    NSString *filenameMinusExt = [filename stringByDeletingPathExtension];
    NSString *filenameExtension = [filename pathExtension];
    
    // Make sure the target file has a unique filename
    NSUInteger suffixNumber = 1;
    while ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
        NSString * newFilename = [[filenameMinusExt stringByAppendingFormat:@"-%u", suffixNumber] stringByAppendingPathExtension:filenameExtension];
        targetPath = [self.archiveFilesDirectory stringByAppendingPathComponent:newFilename];
        suffixNumber++;
        if (suffixNumber > kMaxSuffixesToTry) {
            // Oops, we've wrapped around.
            break;
        }
    }
    
    [[NSFileManager defaultManager] copyItemAtPath:incomingPath
                                            toPath:targetPath
                                             error:&error];
    if (error) {
        NSLog(@"Error copying zip file (%@) to document directory (%@): %@, %@", incomingPath, targetPath, error, error.userInfo);
    } else {
        // Set file's last modified date
        NSDictionary *attrs = [NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate];
        [[NSFileManager defaultManager] setAttributes:attrs
                                         ofItemAtPath:targetPath
                                                error:nil];


        [[NSFileManager defaultManager] removeItemAtPath:incomingPath
                                                   error:&error];
        if (error) {
            NSLog(@"Error deleting %@: %@, %@", incomingPath, error, error.userInfo);
        }
        
        [self.masterViewNavigationController popToRootViewControllerAnimated:NO];
        
        NSError * error = nil;
        ZPFileWrapper *newFileWrapper = [ZPFileWrapper fileWrapperWithURL:[NSURL fileURLWithPath:targetPath]
                                                                    error:&error];
        if (!newFileWrapper) {
            NSLog(@"Error on creating temp file wrapper for newly-arrived zip (%@): %@, %@", targetPath, error, error.userInfo);
        } else {
            ZPFileContainerListViewController *vc = [[ZPFileContainerListViewController alloc] initWithContainer:newFileWrapper];
            [self.masterViewNavigationController pushViewController:vc animated:NO];
            
            // Load the blank view up in the detail view controller
            [self setDetailViewController:nil];
        }
    }
    return YES;
}

- (NSString*)documentsDirectory
{
    static NSString * DocumentsDirectory = nil;
    if (DocumentsDirectory == nil) {
        DocumentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    }
    return DocumentsDirectory;
}

- (NSString*)cacheDirectory
{
    if (!_cacheDirectory) {
        NSString *dir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"archive-contents"];
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            NSLog(@"Error on creating cache directory (%@): %@, %@", dir, error, error.userInfo);
        } else {
            _cacheDirectory = dir;
        }
    }
    return _cacheDirectory;
}

- (NSString*)archiveFilesDirectory
{
    if (!_archiveFilesDirectory) {
        NSString *dir = [self.documentsDirectory stringByAppendingPathComponent:@"zippity-files"];
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            NSLog(@"Error on creating zip file directory (%@): %@, %@", dir, error, error.userInfo);
        } else {
            _archiveFilesDirectory = dir;
        }
    }
    return _archiveFilesDirectory;
}

#pragma mark - iPad-only methods

- (void)applyTintToDetailViewNavigationController
{
    [self.detailViewNavigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"nav-bar-background.png"] forBarMetrics:UIBarMetricsDefault];
    self.detailViewNavigationController.navigationBar.tintColor = kZippityRed;
    self.detailViewNavigationController.toolbar.tintColor = [UIColor colorWithWhite:0.1 alpha:1.0];
}

- (void)setDetailViewController:(UIViewController *)viewController
{
    // Set the detail view controller for the split view controller.
    // If the old detail view controller has a button for opening
    // the popover controller, transfer that button to the new
    // detail view controller, setting its title to the title of
    // the top-most view controller in the master navigation controller
    
    UIViewController *currentViewController = self.detailViewNavigationController.topViewController;

    if (viewController == nil) {
        if ([currentViewController isKindOfClass:[ZPEmptyViewController class]]) {
            // Nothing to do here
            return;
        }
        viewController = [[ZPEmptyViewController alloc] init];
    }
    if (viewController != currentViewController) {
        if (isIpad && UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
        {
            self.masterPopoverButton.title = self.masterViewNavigationController.topViewController.title;
            viewController.navigationItem.leftBarButtonItem = self.masterPopoverButton;
            
            if ([viewController respondsToSelector:@selector(setOriginalLeftBarButtonItem:)]) {
                [(id)viewController setOriginalLeftBarButtonItem:self.masterPopoverButton];
            }
        }
            
        [self.detailViewNavigationController setViewControllers:[NSArray arrayWithObject:viewController] animated:NO];

        if (![viewController isKindOfClass:[ZPImagePreviewController class]]) {
            // Re-apply the Zippity branding
            [self applyTintToDetailViewNavigationController];
        }
    }
}

- (void)dismissMasterPopover
{
    [self.masterPopoverController dismissPopoverAnimated:YES];
}

#pragma mark - UISplitViewController delegate methods

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc
{
    // Set the navigation item's left bar button
    [self.detailViewNavigationController.topViewController.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    
    // If this is a ZPPreviewController object, or anything else with an 
    // originalLeftBarButtonItem property, set that too.
    if ([aViewController respondsToSelector:@selector(setOriginalLeftBarButtonItem:)]) {
        [(id)aViewController setOriginalLeftBarButtonItem:self.masterPopoverButton];
    }
    self.masterPopoverController = pc;
    self.masterPopoverButton = barButtonItem;
    self.masterPopoverButton.title = self.masterViewNavigationController.topViewController.title;
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.detailViewNavigationController.topViewController.navigationItem.leftBarButtonItem = nil;
    self.masterPopoverController = nil;
    self.masterPopoverButton = nil;
}

#pragma mark - UINavigationController delegate methods

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (isIpad && navigationController == self.masterViewNavigationController) {
        self.masterPopoverButton.title = viewController.title;
    }
}

- (void)handleDropboxUploadStartedNotification:(NSNotification *)notification
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSURL *fileURL = notification.userInfo[GSDropboxUploaderFileURLKey];
    NSString *format = NSLocalizedString(@"Uploading %@ to Dropbox", @"Message shown while uploading a file to Dropbox. %@ is replaced by the filename.");
    NSString *message = [NSString stringWithFormat:format, fileURL.lastPathComponent];
    [self.statusBarViewController showMessage:message
                                  withTimeout:0.0];
    [TestFlight passCheckpoint:@"Started uploading a file to Dropbox"];
}

- (void)handleDropboxUploadProgressNotification:(NSNotification *)notification
{
    CGFloat progress = [notification.userInfo[GSDropboxUploaderProgressKey] floatValue];
    [self.statusBarViewController showProgressViewWithProgress:progress];
}

- (void)updateDropboxUploadStatus
{
    if ([[GSDropboxUploader sharedUploader] pendingUploadCount] == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [self.statusBarViewController showProgressViewWithProgress:1.0];
        [self.statusBarViewController showMessage:NSLocalizedString(@"Upload complete", @"Status message shown when Dropbox upload session has completed") withTimeout:3.0];
    }
}

@end
