//
//  ViewController.h
//  Hls
//
//  Created by DeerClass on 2022/2/22.
//

#import <UIKit/UIKit.h>

#define KvideoName @"video.m3u8"
#define KvideoInfo @"videoInfo.plist"
#define kwebUrl(value)   [NSString stringWithFormat:@"http://localhost:9946/%@/video.m3u8",value]
#define kWebCahceRootUrl(value,orginUrl)  [NSString stringWithFormat:@"http://localhost:9946/Cache/%@?orginUrl=%@",value,orginUrl]

@interface ViewController : UIViewController

- (NSString *)getWebCahceRootDir:(NSString *)subdirectory;

- (void)downloadM3u8WithUrl:(NSString *)urlStr isOnceDownload:(BOOL)isOnceDownload;

@end

