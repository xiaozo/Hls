//
//  CustomExceptionHandler.m
//  TestSearch
//
//  Created by zoulixiang on 2018/11/28.
//  Copyright © 2018年 zoulixiang. All rights reserved.
//

#import "CustomExceptionHandler.h"

void UncaughtExceptionHandler(NSException *exception) {
    NSArray *arr = [exception callStackSymbols];
    NSString *reason = [exception reason];
    NSString *name = [exception name];
    NSString *exceptionStr = [NSString stringWithFormat:@"%@\nreason:%@\nname:%@",arr, reason, name];
    NSString *path = [CustomExceptionHandler sharedInstance].exceptionPath;
    [[exceptionStr dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];
    
    
}

static CustomExceptionHandler *_customExceptionHandler;

@implementation CustomExceptionHandler

- (NSString *)exceptionPath {
     NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    NSFileManager *fileManger = [NSFileManager defaultManager];
    NSString *cataloguePath = [NSString stringWithFormat:@"%@/CustomExceptionHandler",path];
    if (![fileManger fileExistsAtPath:cataloguePath]) {
        [fileManger createDirectoryAtPath:cataloguePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
    [dateFormatter setDateFormat:@"MM月dd日 hh:mm:ss"];
     NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    
    return [cataloguePath stringByAppendingPathComponent:dateStr];
}
+ (CustomExceptionHandler *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _customExceptionHandler = [[CustomExceptionHandler alloc] init];
    });
    return _customExceptionHandler;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);
        
    }
    return self;
}


@end
