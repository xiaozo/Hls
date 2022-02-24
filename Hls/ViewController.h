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

@interface ViewController : UIViewController


@end

