//
//  HTCustomURLProtocol.m
//  Hls
//
//  Created by DeerClass on 2022/2/24.
//

#import "HTCustomURLProtocol.h"
#import "AFNetworking.h"
// 定义一个协议 key
static NSCache *cache;

@interface HTCustomURLProtocol ()

@end

@implementation HTCustomURLProtocol

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //注册scheme
        cache = [[NSCache alloc]init];
        cache.countLimit = 50;
    });
}
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
   
    if ([[request URL].absoluteString rangeOfString:@"localhost"].location != NSNotFound) {
        return NO;
    }
    
    if ([[request URL].lastPathComponent rangeOfString:@".mp4"].location != NSNotFound || [[request URL].lastPathComponent rangeOfString:@".flv"].location != NSNotFound) {
        [self alert:@"截取到的地址" url:[request URL].absoluteString];
        return NO;
    }
    
        if ([[request URL].lastPathComponent rangeOfString:@".m3u8"].location != NSNotFound) {
       
        // 6、构造NSURLSessionConfiguration
           NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
           // 7、创建网络会话
           NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
           // 8、创建会话任务
           NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
               // 10、判断是否请求成功
               if (error) {
                   NSLog(@"post error :%@",error.localizedDescription);
               }else {
                   // 如果请求成功，则解析数据。
                   id object = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                   // 11、判断是否解析成功
                
                   if ([object hasPrefix:@"#EXTM3U"] && [object rangeOfString:@"#EXT-X-ENDLIST"].location != NSNotFound) {
                       NSLog(@"post success:%@",request.URL.absoluteString);
                       dispatch_async(dispatch_get_main_queue(), ^{
                          
                           NSString *WebServerCacheDir = [((AppDelegate *)UIApplication.sharedApplication.delegate) getWebServerCacheDir:nil];
                           NSString *m3u8Name = [[NSString md5String:request.URL.absoluteString] stringByAppendingPathExtension:@"m3u8"];
                           NSString *m3u8path = [WebServerCacheDir stringByAppendingPathComponent:m3u8Name];
                           [data writeToFile:m3u8path atomically:YES];
                           
                           NSString *m3u8NameLocalUrlStr = kWebCahceRootUrl(m3u8Name,[request URL].absoluteString);
                           
                           [self alert:@"截取到的m3u8地址" url:m3u8NameLocalUrlStr];
                           
//                           [((AppDelegate *)UIApplication.sharedApplication.delegate) downloadM3u8WithUrl:kWebCahceRootUrl(m3u8Name) isOnceDownload:NO];
                       });
                   }
                   
               }

           }];
           // 9、执行任务
           [task resume];
        return NO;
    }
    
    return NO;
}

+ (void)alert:(NSString *)title url:(NSString *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *md5UrlStr = [NSString md5String:url];
        if ([cache objectForKey:md5UrlStr] != nil) {
            return;
        }
        
        [cache setObject:@"YES" forKey:md5UrlStr];
        
//        [((AppDelegate *)UIApplication.sharedApplication.delegate) downloadM3u8WithUrl:kWebCahceRootUrl(m3u8Name) isOnceDownload:NO];
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:url
                                                                    preferredStyle:UIAlertControllerStyleAlert];

                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                    [UIPasteboard generalPasteboard].string = url;
                 }];
        
        UIAlertAction* downloadAction = [UIAlertAction actionWithTitle:@"添加下载"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [((AppDelegate *)UIApplication.sharedApplication.delegate) alertDownloadWithUrl:url];
            });
            
            
           }];
        
        UIAlertAction* verificationAction = [UIAlertAction actionWithTitle:@"验证"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:url]];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self alert:title url:url];
            });
           
        }];

            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                    style:UIAlertActionStyleCancel
                                                                  handler:^(UIAlertAction * action) {
            }];
            [alert addAction:cancelAction];
            [alert addAction:verificationAction];
        
            [alert addAction:downloadAction];
            [alert addAction:defaultAction];
        
            [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}
@end
