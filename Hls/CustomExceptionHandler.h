//
//  CustomExceptionHandler.h
//  TestSearch
//
//  Created by zoulixiang on 2018/11/28.
//  Copyright © 2018年 zoulixiang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomExceptionHandler : NSObject

@property (copy, nonatomic) NSString *exceptionPath;                //获取异常日志路径

+ (CustomExceptionHandler *)sharedInstance;

@end

