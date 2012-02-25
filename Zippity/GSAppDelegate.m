//
//  GSAppDelegate.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSAppDelegate.h"
#import "TestFlight.h"

#define kMaxSuffixesToTry 100

@interface GSAppDelegate()

- (NSString*)documentsDirectory;

@end

@implementation GSAppDelegate

@synthesize window=_window;
@synthesize rootListViewController=_rootListViewController;
@synthesize navigationController=_navigationController;

- (void)cleanInboxDirectory 
{
    NSString *inboxPath = [self.documentsDirectory stringByAppendingPathComponent:@"Inbox"];
    for (NSString *filename in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:inboxPath error:nil]) {
        NSError *error = nil;
        NSString *filePath = [inboxPath stringByAppendingPathComponent:filename];
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"Error deleting %@: %@, %@", filePath, error, error.userInfo);
        } else {
            NSLog(@"Deleted %@", filePath);
        }
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TestFlight takeOff:@"c9a1cdc85d251c1574f49750c3db2a52_NzcyMzIwMTEtMDktMTYgMDU6MTI6MTkuOTU1OTM3"];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    NSLog(@"Zip files directory: %@", self.zipFilesDirectory);
    
    // Demo mode: add a sample zip file
    NSString *sampleZipFile = [[NSBundle mainBundle] pathForResource:@"Welcome to Zippity.zip" ofType:nil];
    NSString *sampleTargetPath = [self.zipFilesDirectory stringByAppendingPathComponent:[sampleZipFile lastPathComponent]];
    [[NSFileManager defaultManager] removeItemAtPath:sampleTargetPath error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:sampleZipFile toPath:sampleTargetPath error:nil];
    
    // Create a GSFileWrapper object to act as the data source for the
    // root folder's view controller. Set its name with the string I
    // want to appear in the NavigationItem's title.
    
    NSError *error = nil;
    GSFileWrapper * rootFileWrapper = [GSFileWrapper fileWrapperWithURL:[NSURL fileURLWithPath:self.zipFilesDirectory] error:&error];
    if (error) {
        // TODO: handle error
    }
    rootFileWrapper.name = @"Zippity";
    self.rootListViewController = [[GSFileContainerListViewController alloc] initWithContainer:rootFileWrapper];
    self.rootListViewController.isRoot = YES;
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:self.rootListViewController];

    self.window.rootViewController = nc;
    self.navigationController = nc;
    
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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog(@"Opening URL: %@", url);
    
    NSString *incomingPath = [url path];
    NSString *filename = [incomingPath lastPathComponent];
    NSString *targetPath = [self.zipFilesDirectory stringByAppendingPathComponent:filename];
    
    NSError *error = nil;
    
    NSString *filenameMinusExt = [filename stringByDeletingPathExtension];
    NSString *filenameExtension = [filename pathExtension];
    
    // Make sure the target file has a unique filename
    NSUInteger suffixNumber = 1;
    while ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
        NSString * newFilename = [[filenameMinusExt stringByAppendingFormat:@"-%u", suffixNumber] stringByAppendingPathExtension:filenameExtension];
        targetPath = [self.zipFilesDirectory stringByAppendingPathComponent:newFilename];
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
        NSLog(@"Copied %@ to %@", incomingPath, targetPath);

        // Set file's last modified date
        NSDictionary *attrs = [NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate];
        [[NSFileManager defaultManager] setAttributes:attrs
                                         ofItemAtPath:targetPath
                                                error:nil];


        [[NSFileManager defaultManager] removeItemAtPath:incomingPath
                                                   error:&error];
        if (error) {
            NSLog(@"Error deleting %@: %@, %@", incomingPath, error, error.userInfo);
        } else {
            NSLog(@"Deleted %@", incomingPath);
        }
        
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self.rootListViewController.container reloadContainerContents];
        
        NSError * error = nil;
        GSFileWrapper *newFileWrapper = [GSFileWrapper fileWrapperWithURL:[NSURL fileURLWithPath:targetPath]
                                                                    error:&error];
        if (error) {
            NSLog(@"Error on creating temp file wrapper for newly-arrived zip (%@): %@, %@", targetPath, error, error.userInfo);
        } else {
            GSFileContainerListViewController *vc = [[GSFileContainerListViewController alloc] initWithContainer:newFileWrapper];
            [self.navigationController pushViewController:vc animated:NO];
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

- (NSString*)visitedMarkersDirectory
{
    if (!_visitedMarkersDirectory) {
        NSString *dir = [self.documentsDirectory stringByAppendingPathComponent:@"zippity-visited-markers"];
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            NSLog(@"Error on creating visited markers directory (%@): %@, %@", dir, error, error.userInfo);
        } else {
            _visitedMarkersDirectory = dir;
        }
    }
    return _visitedMarkersDirectory;
}

- (NSString*)zipFilesDirectory
{
    if (!_zipFilesDirectory) {
        NSString *dir = [self.documentsDirectory stringByAppendingPathComponent:@"zippity-files"];
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            NSLog(@"Error on creating zip file directory (%@): %@, %@", dir, error, error.userInfo);
        } else {
            _zipFilesDirectory = dir;
        }
    }
    return _zipFilesDirectory;
}

@end
