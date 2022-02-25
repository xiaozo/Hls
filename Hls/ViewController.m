//
//  ViewController.m
//  Hls
//
//  Created by DeerClass on 2022/2/22.
//

#import "ViewController.h"
#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "YDHTTPConnection.h"
#import "AFNetworking.h"
#import "WKWebViewController.h"
#import "MBProgressHUD.h"
#import "NSString+RegexCheck.h"
#import "QDNetServerDownLoadTool.h"

//NSString *urlstr = @"https://abc.xkys.tv/m3u8/hashbe0906609b32f6d254a80dcbf2f38750.m3u8";
//http://localhost:9946/hashbe0906609b32f6d254a80dcbf2f38750/video.m3u8
//https://pcvideotxott.titan.mgtv.com.8old.cn/player/video/data/d5ba5a16a92bc364d312278164e2e8c8.m3u8

static const int ddLogLevel = LOG_LEVEL_WARN;

@interface Downloaded : NSObject

@property (copy, nonatomic) NSString *webUrl;

@property (copy, nonatomic) NSString *name;

@property (copy, nonatomic) NSString *filePath;

- (instancetype)initWithWebUrl:(NSString *)webUrl name:(NSString *)name filePath:(NSString *)filePath;

@end

@implementation Downloaded

- (instancetype)initWithWebUrl:(NSString *)webUrl name:(NSString *)name filePath:(NSString *)filePath {
    if (self = [super init]) {
        self.webUrl = webUrl;
        self.name = name;
        self.filePath = filePath;
    }
    return self;
}

@end

@interface ViewController () <UITableViewDelegate,UITableViewDataSource>
{
    HTTPServer *httpServer;
    AFHTTPSessionManager *manager;
    
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *downloadedList;

@property (strong, nonatomic) NSMutableArray *undownloadedList;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [self startServer];
    
    manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
//    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [self loadDownLoadedList:nil];
    
}

- (void)showTip:(NSString *)msg {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    // Set the text mode to show only text.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = msg;
    // Move to bottm center.
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);

    [hud hideAnimated:YES afterDelay:2.0];
}
- (IBAction)goweb:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"地址"
                                                                             message:@"请输入网页地址"
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    // 2.1 添加文本框
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"url";
        textField.text = @"https://www.chok8.com";
        textField.clearButtonMode = UITextFieldViewModeAlways;
    }];
 

    // 2.2  创建Cancel Login按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Cancel Action");
    }];
    UIAlertAction *loginAction = [UIAlertAction actionWithTitle:@"go" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *url = alertController.textFields.firstObject;
       
        if (url.text.checkUrl) {
            NSString *urlStr = url.text;
            WKWebViewController *dst = [[WKWebViewController alloc] init];
            
            dst.isOpenInterceptReq = YES;
            [dst loadWebURLSring:urlStr];
            
            [self.navigationController pushViewController:dst animated:YES];
            
     
        } else {
            [self showTip:@"url不正确"];
        }
       
    }];

 // 2.3 添加按钮
    [alertController addAction:cancelAction];
    [alertController addAction:loginAction];

 [self presentViewController:alertController animated:YES completion:nil];
    
}

- (IBAction)reset:(id)sender {
    [self startServer];
    
}

- (IBAction)inputAdree:(id)sender {
    
    // 1.创建UIAlertController
    
       UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"地址"
                                                                                message:@"请输入m3u8地址"
                                                                         preferredStyle:UIAlertControllerStyleAlert];

       // 2.1 添加文本框
       [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
           textField.placeholder = @"url";
           textField.text = [[UIPasteboard generalPasteboard] string];
           textField.clearButtonMode = UITextFieldViewModeAlways;
       }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"name";
        textField.clearButtonMode = UITextFieldViewModeAlways;
    }];


       // 2.2  创建Cancel Login按钮
       UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
           NSLog(@"Cancel Action");
       }];
       UIAlertAction *loginAction = [UIAlertAction actionWithTitle:@"下载" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
           UITextField *url = alertController.textFields.firstObject;
           UITextField *name = alertController.textFields.lastObject;
           if (url.text.checkUrl) {
               NSString *urlStr = url.text;
               urlStr = [urlStr urlAddCompnentForValue:name.text key:@"videoName"];
               [self downloadWithUrl:urlStr isOnceDownload:YES];
           } else {
               [self showTip:@"url不正确"];
           }
          
       }];

    // 2.3 添加按钮
       [alertController addAction:cancelAction];
       [alertController addAction:loginAction];

    [self.navigationController presentViewController:alertController animated:YES completion:nil];
    
}


- (void)loadDownLoadedList:(CommonVoidBlock)block {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @synchronized (self) {
            NSMutableArray *undownloadedList = @[].mutableCopy;
            NSString *BASE_PATH = [self getTempDirWithUrlStr:nil];
               NSFileManager *myFileManager = [NSFileManager defaultManager];
               NSArray *myDirectorys = [myFileManager contentsOfDirectoryAtPath:BASE_PATH error:nil];
            for (NSString *directory in myDirectorys) {
                if ([directory rangeOfString:@"."].location == 0
                    || [directory isEqualToString:@"Cache"]) {
                    ///过滤隐藏文件
                    continue;
                }
                
//                NSString *name = directory;
//                NSString *url = @"";
//                [undownloadedList addObject:[[Downloaded alloc] initWithWebUrl:url name:name]];
                NSString *videoInfoPath = [[BASE_PATH stringByAppendingPathComponent:directory] stringByAppendingPathComponent:KvideoInfo];
                if (![myFileManager fileExistsAtPath:videoInfoPath]) {
                    ///不存在
                    continue;
                }
                
                NSMutableDictionary *videoInfoDict = [[NSMutableDictionary alloc]initWithContentsOfFile:videoInfoPath];
                NSString *name = [videoInfoDict valueForKey:@"name"];;
                NSString *url = [videoInfoDict valueForKey:@"net_url"];
                NSString *filePath = [BASE_PATH stringByAppendingPathComponent:directory];
                [undownloadedList addObject:[[Downloaded alloc] initWithWebUrl:url name:name filePath:filePath]];
                
            }
            self.undownloadedList = undownloadedList;
            
            NSMutableArray *downloadedList = @[].mutableCopy;
            BASE_PATH = [self getWebServerRootDir:nil];
            myDirectorys = [myFileManager contentsOfDirectoryAtPath:BASE_PATH error:nil];
            for (NSString *directory in myDirectorys) {
                if ([directory rangeOfString:@"."].location == 0) {
                    ///过滤隐藏文件
                    continue;
                }
                
                NSString *videoInfoPath = [[BASE_PATH stringByAppendingPathComponent:directory] stringByAppendingPathComponent:KvideoInfo];
                if (![myFileManager fileExistsAtPath:videoInfoPath]) {
                    ///不存在
                    continue;
                }
                
                NSMutableDictionary *videoInfoDict = [[NSMutableDictionary alloc]initWithContentsOfFile:videoInfoPath];
                NSString *name = [videoInfoDict valueForKey:@"name"];
                NSString *webFileName = [videoInfoDict valueForKey:@"web_file_name"] ? : KvideoName;
                NSString *url = kwebUrl([directory stringByAppendingPathComponent:webFileName]);
                NSString *filePath = [BASE_PATH stringByAppendingPathComponent:directory];
                [downloadedList addObject:[[Downloaded alloc] initWithWebUrl:url name:name filePath:filePath]];
                
            }
            self.downloadedList = downloadedList;
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            if (block) {
                block();
            }
        });
        
    });
}

- (void)loadNextUnDownload {
    Downloaded *download;
    @synchronized (self) {
        if (self.undownloadedList.count) {
            download = self.undownloadedList.firstObject;
        }
    }
    
    if (download) {
        [self downloadWithUrl:download.webUrl isOnceDownload:YES];
    }
}

- (void)startServer
{
    // Configure our logging framework.
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // Initalize our http server
    httpServer = [[HTTPServer alloc] init];
    
    // Tell the server to broadcast its presence via Bonjour.
    [httpServer setType:@"_http._tcp."];
    
    // Normally there's no need to run our server on any specific port.
    [httpServer setPort:9946];
    
    // We're going to extend the base HTTPConnection class with our MyHTTPConnection class.
    [httpServer setConnectionClass:[YDHTTPConnection class]];
    
    // Serve files from our embedded Web folder
    [httpServer setDocumentRoot:[self getWebServerRootDir:nil]];
    
    NSLog(@"%@",[self getWebServerRootDir:nil]);
    
    NSError *error = nil;
    if(![httpServer start:&error])
    {
        DDLogError(@"Error starting HTTP Server: %@", error);
    }
}

///得本地服务root目录
/// @param subdirectory 子目录  aaa/bbb
- (NSString *)getWebServerRootDir:(NSString *)subdirectory {
    //  在Documents目录下创建一个名为FileData的文件夹
    ///https://abc.xkys.tv/m3u8/hashbe0906609b32f6d254a80dcbf2f38750.m3u8
    NSString *path = [NSString stringWithFormat:@"%@/ZYKJAppServerRoot",[PathUtility getDocumentPath]];
   
    
    NSFileManager *fm  = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path
      withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    path = subdirectory.length ? [path stringByAppendingPathComponent:subdirectory] : path;
    
    return path;
}

- (NSString *)getWebCahceRootDir:(NSString *)subdirectory {
    NSString *rootPath = [self getWebServerRootDir:nil];
    
    NSFileManager *fm  = [NSFileManager defaultManager];
    
    subdirectory = subdirectory.length ? [NSString stringWithFormat:@"Cache/%@",subdirectory] : @"Cache";
    NSString *path = [rootPath stringByAppendingPathComponent:subdirectory];
    
   
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path
      withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return path;
}

////根据url获取目录名字
- (NSString *)getTempDirNameWithUrlStr:(NSString *)urlStr {
    return [NSString md5String:urlStr];
}

///根据m3u8的具体资源地址获取文件名
- (NSString *)localTsNameByTsUrlStr:(NSString *)tsUrlStr {
    return [NSString md5String:tsUrlStr];
}

///根据url获取临时下载目录
- (NSString *)getTempDirWithUrlStr:(NSString *)urlStr {
    
    NSString *path = [NSString stringWithFormat:@"%@/videoTemp",[PathUtility getDocumentPath]];
    
    NSFileManager *fm  = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createDirectoryAtPath:path
      withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (urlStr.length) {
        NSString *subdirectory = [self getTempDirNameWithUrlStr:urlStr];
        path = subdirectory.length ? [path stringByAppendingPathComponent:subdirectory] : path;
        if (![fm fileExistsAtPath:path]) {
            [fm createDirectoryAtPath:path
          withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    
    return path;
}



static MBProgressHUD *m3u8filehud;
static MBProgressHUD *hud;
static NSURLSessionDownloadTask *downloadTask;
- (void)downloadWithUrl:(NSString *)urlStr isOnceDownload:(BOOL)isOnceDownload {
    if ([urlStr rangeOfString:@".mp4"].location != NSNotFound) {
        [self downloadCommonWithUrl:urlStr isOnceDownload:isOnceDownload];
    } else {
        [self downloadM3u8WithUrl:urlStr isOnceDownload:isOnceDownload];
    }
    
}

- (void)downloadCommonWithUrl:(NSString *)urlStr isOnceDownload:(BOOL)isOnceDownload {
   
    
    // Set the determinate mode to show task progress.
    
    NSString *fileName = [NSString md5String:urlStr];
    NSString *videoInfoPath = [[self getTempDirWithUrlStr:urlStr] stringByAppendingPathComponent:KvideoInfo];
    NSString *path = [[self getTempDirWithUrlStr:urlStr] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",[NSURL URLWithString:urlStr].lastPathComponent]];
    
    NSMutableDictionary *vidoInfoDict = [[NSMutableDictionary alloc] init];
    
      //设置属性值
    fileName = [NSString paramValueOfUrl:urlStr withParam:@"videoName"] ? [NSString stringWithFormat:@"%@_%@",[NSString paramValueOfUrl:urlStr withParam:@"videoName"],fileName]: fileName;
      [vidoInfoDict setObject:fileName forKey:@"name"];
      [vidoInfoDict setObject:urlStr forKey:@"net_url"];
      [vidoInfoDict setObject:[NSURL URLWithString:urlStr].lastPathComponent forKey:@"web_file_name"];
    
    //写入文件
    [vidoInfoDict writeToFile:videoInfoPath atomically:YES];
    [self loadDownLoadedList:nil];
    
    @synchronized (self) {
        if (hud) return;
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeDeterminate;
        hud.label.text = @"下载中。。";

        // Set up NSProgress
        hud.progress = 0;
        // Configure a cancel button.
        [hud.button setTitle:NSLocalizedString(@"Cancel", @"HUD cancel button title") forState:UIControlStateNormal];
        [hud.button addTarget:self action:@selector(cancelCommonDownload) forControlEvents:UIControlEventTouchUpInside];
    }
    
    NSURLSessionDownloadTask *tempTask = [[QDNetServerDownLoadTool sharedTool]AFDownLoadFileWithUrl:urlStr progress:^(CGFloat progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.progress = progress;
            NSLog(@"%.2f",hud.progress);
        });
    } fileLocalUrl:[NSURL fileURLWithPath:path isDirectory:NO] success:^(NSURL *fileUrlPath, NSURLResponse *response) {
        
        NSLog(@"全部下载完毕");
        NSString *subdirectory = [self getTempDirNameWithUrlStr:urlStr];
        [[NSFileManager defaultManager] moveItemAtPath:[self getTempDirWithUrlStr:urlStr] toPath:[self getWebServerRootDir:subdirectory] error:nil];
        
        [self deallocDownload];
        
        [self loadDownLoadedList:^{
            [self loadNextUnDownload];
        }];
        
      
    } failure:^(NSError *error, NSInteger statusCode) {
        NSLog(@"下载失败,下载的data被downLoad工具处理了 ");
        [self showTip:error.localizedDescription];
        [self deallocDownload];
        
    }];
    downloadTask = tempTask;
    
    
}

- (void)downloadM3u8WithUrl:(NSString *)urlStr isOnceDownload:(BOOL)isOnceDownload{
    
    @synchronized (self) {
        if (m3u8filehud) return;
        m3u8filehud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    
    NSString *m3u8Name = [NSString md5String:urlStr];
    NSString *orginUrlStr = [NSString paramValueOfUrl:urlStr withParam:@"orginUrl"].length ? [NSString paramValueOfUrl:urlStr withParam:@"orginUrl"] : urlStr;
    
   NSString *path = [[self getTempDirWithUrlStr:urlStr] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m3u8",m3u8Name]];
   NSString *accessPath = [[self getTempDirWithUrlStr:urlStr] stringByAppendingPathComponent:KvideoName];
    NSString *videoInfoPath = [[self getTempDirWithUrlStr:urlStr] stringByAppendingPathComponent:KvideoInfo];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:videoInfoPath]) {
        NSMutableDictionary *vidoInfoDict = [[NSMutableDictionary alloc] init];
          //设置属性值
          m3u8Name = [NSString paramValueOfUrl:urlStr withParam:@"videoName"] ? [NSString stringWithFormat:@"%@_%@",[NSString paramValueOfUrl:urlStr withParam:@"videoName"],m3u8Name]: m3u8Name;
          [vidoInfoDict setObject:m3u8Name forKey:@"name"];
          [vidoInfoDict setObject:urlStr forKey:@"net_url"];
        
        //写入文件
        [vidoInfoDict writeToFile:videoInfoPath atomically:YES];
        
        [self loadDownLoadedList:nil];
    }
   
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData *data = [[NSFileManager defaultManager] fileExistsAtPath:path] ? [NSData dataWithContentsOfFile:path] : [NSData dataWithContentsOfURL:[NSURL URLWithString:urlStr]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                ///写文件
                [data writeToFile:path atomically:YES];
                
                ///
                NSString *m3u8Content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
        //        NSString *regulaStr = @"\\bhttps?://[a-zA-Z0-9\\-.]+(?::(\\d+))?(?:(?:/[a-zA-Z0-9\\-._?,'+\\&%$=~*!():@\\\\]*)+)?";
        //        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr
        //                                                                                  options:NSRegularExpressionCaseInsensitive
        //                                                                                    error:nil];
        //           NSArray *arrayOfAllMatches = [regex matchesInString:m3u8Content options:0 range:NSMakeRange(0, [m3u8Content length])];
        //        NSMutableArray *m3u8FileUrlStrs = @[].mutableCopy;
        //           for (NSTextCheckingResult *match in arrayOfAllMatches)
        //           {
        //               NSString* substringForMatch = [m3u8Content substringWithRange:match.range];
        //               [m3u8FileUrlStrs addObject:substringForMatch];
        //
        //           }
                
                NSMutableArray *m3u8FileUrlStrs = @[].mutableCopy;
                NSArray *array = [m3u8Content componentsSeparatedByString:@"\n"];
                NSMutableString *videoM3u8 = @"".mutableCopy;
                
                for (NSString *line in array) {
                    NSString *tline = line;
                    NSString *regulaStr = @"\\bhttps?://[a-zA-Z0-9\\-.]+(?::(\\d+))?(?:(?:/[a-zA-Z0-9\\-._?,'+\\&%$=~*!():@\\\\]*)+)?";
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr
                                                                                              options:NSRegularExpressionCaseInsensitive
                                                                                                error:nil];
                    NSArray *arrayOfAllMatches = [regex matchesInString:line options:0 range:NSMakeRange(0, [line length])];
                    if (arrayOfAllMatches.count) {
                        ///匹配到url
                        NSString* substringForMatch = [tline substringWithRange:((NSTextCheckingResult *)arrayOfAllMatches.firstObject).range];
                        [m3u8FileUrlStrs addObject:substringForMatch];
                        tline = [NSString stringWithFormat:@"%@/%@",@"<hls/>", [self localTsNameByTsUrlStr:substringForMatch]];
                    } else if ([tline rangeOfString:@".ts"].location != NSNotFound) {
                        ///ts结尾
                        if ([tline hasPrefix:@"/"]) {
                            ///绝对路径
                            NSString *substringForMatch = [NSString stringWithFormat:@"%@://%@/%@",[NSURL URLWithString:orginUrlStr].scheme, [NSURL URLWithString:orginUrlStr].host,tline];
                            [m3u8FileUrlStrs addObject:substringForMatch];
                            tline = [NSString stringWithFormat:@"%@/%@",@"<hls/>", [self localTsNameByTsUrlStr:substringForMatch]];
                        } else {
                            /// 相对路径路径
                            NSString* lastPathComponent = [NSURL URLWithString:orginUrlStr].lastPathComponent;
                            NSInteger index = [orginUrlStr rangeOfString:lastPathComponent].location;
                            NSString *substringForMatch = [NSString stringWithFormat:@"%@/%@",[orginUrlStr substringToIndex:index],tline];
                            [m3u8FileUrlStrs addObject:substringForMatch];
                            tline = [NSString stringWithFormat:@"%@/%@",@"<hls/>", [self localTsNameByTsUrlStr:substringForMatch]];
                        }
                      
                        
                    } 
                    
                    [videoM3u8 appendString:tline];
                    [videoM3u8 appendString:@"\n"];
                }
                
                [videoM3u8 writeToFile:accessPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                
                [m3u8filehud hideAnimated:YES];
                m3u8filehud = nil;

                if (isOnceDownload) {
                    
                    @synchronized (self) {
                        ///加个锁
                        if (hud) return;
                        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    }
                    
                    // Set the determinate mode to show task progress.
                    hud.mode = MBProgressHUDModeDeterminate;
                    hud.label.text = @"下载中。。";

                    // Set up NSProgress
                    NSProgress *progressObject = [NSProgress progressWithTotalUnitCount:m3u8FileUrlStrs.count];
                    hud.progressObject = progressObject;

                    // Configure a cancel button.
                    [hud.button setTitle:NSLocalizedString(@"Cancel", @"HUD cancel button title") forState:UIControlStateNormal];
                    [hud.button addTarget:self action:@selector(cancelDownload) forControlEvents:UIControlEventTouchUpInside];

                    
                    [self downloadM3u8WithM3u8FileUrlStrs:m3u8FileUrlStrs Url:urlStr];
                }
             
            }
        });
    });
  
}

- (void)downloadM3u8WithM3u8FileUrlStrs:(NSMutableArray *)m3u8FileUrlStrs Url:(NSString *)urlStr{
    
    
    @synchronized (self) {
        ///加个锁
        if (hud == nil) {
            return;
        }
    }
    
    if (m3u8FileUrlStrs.count == 0) {
//    if (1) {
        NSLog(@"全部下载完毕");
        NSString *accessPath = [[self getTempDirWithUrlStr:urlStr] stringByAppendingPathComponent:KvideoName];
        NSString *subdirectory = [self getTempDirNameWithUrlStr:urlStr];
        NSString *m3u8Content = [[NSString alloc] initWithContentsOfFile:accessPath encoding:NSUTF8StringEncoding error:nil];
        m3u8Content = [m3u8Content stringByReplacingOccurrencesOfString:@"<hls/>" withString:[NSString stringWithFormat:@"/%@/",subdirectory]];
        [m3u8Content writeToFile:accessPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        [[NSFileManager defaultManager] moveItemAtPath:[self getTempDirWithUrlStr:urlStr] toPath:[self getWebServerRootDir:subdirectory] error:nil];
        
        [self deallocDownload];
        
        [self loadDownLoadedList:^{
            [self loadNextUnDownload];
        }];
        
        return;
    }
    NSURL *subfileUrl = [NSURL URLWithString:m3u8FileUrlStrs.firstObject];
    
    NSString *subfile = [[self getTempDirWithUrlStr:urlStr] stringByAppendingPathComponent:[self localTsNameByTsUrlStr:m3u8FileUrlStrs.firstObject]];
//       　　　　 NSLog(@"substringForMatch");
    /* 开始请求下载 */
    if ([[NSFileManager defaultManager] fileExistsAtPath:subfile]) {
        [m3u8FileUrlStrs removeObjectAtIndex:0];
        [self downloadM3u8WithM3u8FileUrlStrs:m3u8FileUrlStrs Url:urlStr];
        
        [hud.progressObject becomeCurrentWithPendingUnitCount:1];
        [hud.progressObject resignCurrent];
        
    } else {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:subfileUrl];
        [request addValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15" forHTTPHeaderField:@"User-Agent"];
        downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            NSLog(@"下载进度：%.0f％", downloadProgress.fractionCompleted * 100);
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            /* 设定下载到的位置 */
            return [NSURL fileURLWithPath:subfile];
                    
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
             NSLog(@"下载完成");
            if (!error) {
                [m3u8FileUrlStrs removeObjectAtIndex:0];
                [self downloadM3u8WithM3u8FileUrlStrs:m3u8FileUrlStrs Url:urlStr];
                
                [hud.progressObject becomeCurrentWithPendingUnitCount:1];
                [hud.progressObject resignCurrent];
            } else {
                [self showTip:error.localizedDescription];
                [self deallocDownload];
            }
           
            
        }];
         [downloadTask resume];
    }
    
}

- (void)cancelDownload {
    [downloadTask cancel];
    [hud.progressObject cancel];
    [hud hideAnimated:YES];
    
    [self deallocDownload];
}

- (void)cancelCommonDownload {
    [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
    }];
    
    [hud hideAnimated:YES];
    
    [self deallocDownload];
}


- (void)deallocDownload {
    [hud hideAnimated:YES];
    downloadTask = nil;
    hud = nil;
}

#pragma mark- tableView delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:12.0];
    label.backgroundColor = RGBA(220, 220, 220, 1);
    NSString *title;
    if (section == 0) {
        title = @"未下载";
    } else {
        title = @"已下载";
    }
    label.text = title;
    
    return label;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   
    if (section == 0) {
        return _undownloadedList.count;
    }
    return _downloadedList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        Downloaded *download = _undownloadedList[indexPath.row];
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        cell.textLabel.text = download.name;
        return cell;
    }
    
    Downloaded *download = _downloadedList[indexPath.row];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text = download.name;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.section == 0) {
        Downloaded *download = _undownloadedList[indexPath.row];
        [self downloadWithUrl:download.webUrl isOnceDownload:YES];
        return;
    }
    
    Downloaded *download = _downloadedList[indexPath.row];
    WKWebViewController *dst = [[WKWebViewController alloc] init];
    [dst loadWebURLSring:download.webUrl];
    
    [self.navigationController pushViewController:dst animated:YES];
    
}


//设置可移动
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {}

//设置可编辑的样式
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
    
        NSMutableArray *actions =[NSMutableArray array];
        
        
        
        UITableViewRowAction *delRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
            Downloaded *download;
            if (indexPath.section == 0) {
                download = self.undownloadedList[indexPath.row];
              
            } else {
                download = self.downloadedList[indexPath.row];
                
            }
            
            hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [[NSFileManager defaultManager] removeItemAtPath:download.filePath error:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loadDownLoadedList:^{
                        [hud hideAnimated:YES];
                        hud = nil;
                    }];
                   
                   
                });
            });
         
                
           
        }];
        delRowAction.backgroundColor = kRedColor;
        [actions insertObject:delRowAction atIndex:0];
        
        
        return actions;
    
  
    
}


@end
