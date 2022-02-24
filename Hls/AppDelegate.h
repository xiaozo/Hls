//
//  AppDelegate.h
//  Hls
//
//  Created by DeerClass on 2022/2/22.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (NSString *)getWebServerCacheDir:(NSString *)subdirectory;
- (void)downloadM3u8WithUrl:(NSString *)urlStr isOnceDownload:(BOOL)isOnceDownload;

@end

