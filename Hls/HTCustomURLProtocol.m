//
//  HTCustomURLProtocol.m
//  Hls
//
//  Created by DeerClass on 2022/2/24.
//

#import "HTCustomURLProtocol.h"
#import "AFNetworking.h"
// 定义一个协议 key
static NSString * const HTCustomURLProtocolHandledKey = @"HTCustomURLProtocolHandledKey";

@interface HTCustomURLProtocol ()

@end

@implementation HTCustomURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
   
    if ([[request URL].absoluteString rangeOfString:@"m3u8"].location != NSNotFound) {
       
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
                   NSLog(@"post success :%@",object);
               }

           }];
           // 9、执行任务
           [task resume];
        return NO;
    }
    
    return NO;
}
@end
