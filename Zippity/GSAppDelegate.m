//
//  GSAppDelegate.m
//  Zippity
//
//  Created by Simon Whitaker on 16/02/2012.
//  Copyright (c) 2012 Goo Software Ltd. All rights reserved.
//

#import "GSAppDelegate.h"
#import "GSFileContainerListViewController.h"
#import "GSDirectory.h"

@implementation GSAppDelegate

@synthesize window=_window;
@synthesize rootDirectory=_rootDirectory;

NSString * const GSAppReceivedZipFileNotification = @"GSAppReceivedZipFileNotification";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    NSLog(@"Root directory: %@", self.rootDirectory);
    
    // Demo mode: add a sample zip file
    NSString *sampleZipFile = [[NSBundle mainBundle] pathForResource:@"Test data.zip" ofType:nil];
    NSString *sampleTargetPath = [self.rootDirectory stringByAppendingPathComponent:[sampleZipFile lastPathComponent]];
    [[NSFileManager defaultManager] copyItemAtPath:sampleZipFile toPath:sampleTargetPath error:nil];
    
    // Create a GSDirectory object to act as the data source for the
    // root folder's view controller. Set its name with the string I
    // want to appear in the NavigationItem's title.
    GSDirectory *rootDirectory = [GSDirectory directoryWithPath:self.rootDirectory];
    rootDirectory.name = @"Zippity";
    
    GSFileContainerListViewController *vc = [[GSFileContainerListViewController alloc] initWithStyle:UITableViewStylePlain];
    vc.container = rootDirectory;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];

    self.window.rootViewController = nc;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
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
    NSString *targetPath = [self.rootDirectory stringByAppendingPathComponent:filename];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:incomingPath
                                            toPath:targetPath
                                             error:&error];
    if (error) {
        NSLog(@"Error copying zip file (%@) to document directory (%@): %@, %@", incomingPath, targetPath, error, error.userInfo);
    } else {
        NSLog(@"Saved %@ to %@", incomingPath, targetPath);
        NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithCapacity:1];
        [payload setObject:targetPath forKey:kGSZipFilePathKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:GSAppReceivedZipFileNotification
                                                            object:self
                                                          userInfo:payload];
    }
    return YES;
}

- (NSString*)rootDirectory
{
    if (!_rootDirectory) {
        NSString *rootDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"zippity-files"];
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:rootDirectory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) {
            NSLog(@"Error on creating root directory (%@): %@, %@", rootDirectory, error, error.userInfo);
        } else {
            _rootDirectory = rootDirectory;
        }
    }
    return _rootDirectory;
}

@end
