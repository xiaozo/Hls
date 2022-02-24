//
//  AppDelegate.m
//  Hls
//
//  Created by DeerClass on 2022/2/22.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate () {
    UIBackgroundTaskIdentifier bgTask;
}

@end

@implementation AppDelegate
- (ViewController *)viewController {
    return ((UINavigationController *)UIApplication.sharedApplication.keyWindow.rootViewController).viewControllers.firstObject;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    return YES;
}

- (NSString *)getWebServerCacheDir:(NSString *)subdirectory {
    return [self.viewController getWebCahceRootDir:subdirectory];
}

- (void)downloadM3u8WithUrl:(NSString *)urlStr isOnceDownload:(BOOL)isOnceDownload {
    [self.viewController downloadM3u8WithUrl:urlStr isOnceDownload:NO];
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    bgTask = [application beginBackgroundTaskWithName:@"MyTask" expirationHandler:^{
            // Clean up any unfinished task business by marking where you
            // stopped or ending the task outright.
        
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
}


@end
