//
//  DownloadFile.m
//  07-文件下载
//
//  Created by Apple on 16/6/5.
//  Copyright © 2016年 Apple. All rights reserved.
//

#import "DownloadFile.h"

@interface DownloadFile () <NSURLConnectionDataDelegate>

/// 文件总大小
@property (nonatomic, assign) long long expectedLength;
/// 当前获取到的文件总大小
@property (nonatomic, assign) long long currentTotalLength;
/// 管道
@property (nonatomic, strong) NSOutputStream *stream;
/// 文件保存的路径
@property (nonatomic, copy) NSString *filePath;
/// connection
@property (nonatomic, strong) NSURLConnection *connection;

@end

// 注意 !!! 文件下载不要用这个代理 : NSURLConnectionDownloadDelegate

/*
 1.直接使用GET请求实现文件下载的问题
     问题1 : 内存瞬间暴涨
     问题2 : 无法检测下载的进度
     解决文件下载时的两个问题 : NSURLConnectionDataDelegate
 
 2.didReceiveData : 这个方法调用非常频繁的,不要在主线程执行
    解决办法 : 把设置代理的过程放在子线程,因为设置代理的线程和代理方法执行的线程是一致的
 
 3.子线程的消息循环不开启,所以我们要手动的开启子线程的消息循环,然后代理方法才会在子线程中执行.
 
 4.问题 : 这个代理没有给我们实现缓存
    dataM   OK
    NSFileHandle OK
    NSOutputStream   OK
 
 5.断点续传
     断点续传的思路分析 :
         1.当本地文件的大小 == 服务器文件的大小 ==> 不需要再下载了
         2.当本地文件 > 服务器文件 ==> 删除以前的文件,从头开始重新下载
         3.当本地文件 < 服务器文件 ==> 接着下(续传)
    
     断点续传的步骤:
         1.获取服务器文件的大小 (发送同步HEAD请求,只获取响应头)
         2.获取本地文件的大小
         3.比较本地文件和服务器文件的大小,比较会有结果
            比较的结果作用 : 告诉服务器你怎么怎么给我传数据
            结论 : 通过设置requestM告诉服务器一些额外信息
 
 */

@implementation DownloadFile

/// 暂停下载 进度 0.771970
- (void)pauseDownload
{
    // 提示 : 一旦调用了 cancel,那么继续下载的时候,就需要重新的建立connection.
    [self.connection cancel];
    
    NSLog(@"暂停下载");
}

/// 文件下载
- (void)downloadFileURLString:(NSString *)URLString
{
    // URL
    NSURL *URL = [NSURL URLWithString:URLString];
    // 不可变的请求 (默认就是GET)
    NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:URL];
    
    // 在发送请求之前,就要确定好服务器该怎么给我传数据,因为是通过设置request告诉服务器怎么传数据的;
    // 提示 : 如果已经开始下载,再去设置request,就已经晚了.
    // 发送同步HEAD请求 : 同步请求不结束,后面的代码不会执行,所以保证我拿到文件的总大小之后,采取设置request
    self.expectedLength = [self getServerFileSizeWithURL:URL];
    
    // 在获取到服务器文件大小之后,在发送请求之前,比较本地文件和服务器文件大小
    // 用文件当前的总大小(currentTotalLength)去接收比较的结果
    self.currentTotalLength = [self getLocalFileSizeAndCompareWithServerFileSize];
    
    // 如果本地文件和服务器文件一般大就不再下载
    if (self.currentTotalLength == -1) {
        NSLog(@"文件已经下载好了,别再下了");
        return;
    }
    
    // 告诉服务器该怎么下载 : 就是设置 request , 设置它的 Range 字段;
    NSString *range = [NSString stringWithFormat:@"bytes=%lld-",self.currentTotalLength];
    [requestM setValue:range forHTTPHeaderField:@"Range"];
    
    // 设置NSURLConnection的代理,使用代理去实现文件的下载
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        // 这句话执行完,就开始使用代理方法去下载
         self.connection = [NSURLConnection connectionWithRequest:requestM delegate:self];
        
        // 手动开启当前子线程的消息循环.
        // 提示 : 这个消息循环在文件下载结束之后,会由NSURLConnection自动的关闭
        [[NSRunLoop currentRunLoop] run];
    }];
}

#pragma mark - 获取本地文件的大小,与服务器文件比较,得到比较的结果
- (long long)getLocalFileSizeAndCompareWithServerFileSize
{
    long long result = 0;
    
    // 获取本地文件的大小
    NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:NULL];
    long long localFileSize = fileAttr.fileSize;
    
    // 与服务器文件大小比较 : expectedLength 就是服务器文件的大小
    
    // 1.当本地文件的大小 == 服务器文件的大小 ==> 不需要再下载了
    if (localFileSize == self.expectedLength) {
        // -1只是一个特殊的标记而已,你们可以自己去设计.
        result = -1;
    }
    
    // 2.当本地文件 < 服务器文件 ==> 接着下(续传)
    if (localFileSize < self.expectedLength) {
        result = localFileSize;
    }
    
    // 3.当本地文件 > 服务器文件 ==> 删除以前的文件,从头开始重新下载
    if (localFileSize > self.expectedLength) {
        // 删除错误的文件
        [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:NULL];
        // 从0开始下载
        result = 0;
    }
    
    // 把比较的结果返回出去
    
    return result;
}

#pragma mark - 发送HEAD请求,获取服务器文件总大小
- (long long)getServerFileSizeWithURL:(NSURL *)URL
{
    // 创建可变的请求
    NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:URL];
    // 设置请求方法
    requestM.HTTPMethod = @"HEAD";
    // 定义空的Response
    NSURLResponse *response;
    // 发送同步的HEAD请求
    [NSURLConnection sendSynchronousRequest:requestM returningResponse:&response error:NULL];
    
    // 获取响应头 : 取出服务器文件的总大小
    long long expectedLength = response.expectedContentLength;
    NSLog(@"文件总大小 %lld",expectedLength);
    
    // 拼接文件保存在沙盒/桌面的路径
//    response.suggestedFilename;
    self.filePath = [NSString stringWithFormat:@"/Users/apple/Desktop/%@",response.suggestedFilename];
    
    return expectedLength;
}


#pragma Mark - NSURLConnectionDataDelegate

/// 接收到请求头之后,就会调用的 : 可以拿到文件的总大小
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // 2.创建stream 流/管道
    self.stream = [NSOutputStream outputStreamToFileAtPath:self.filePath append:YES];
    // 3.打开
    [self.stream open];
}

/// 实时接收服务器发送的数据 : 可以获取每次发送的数据,把每次发送的数据做拼接,就可以计算当前一共下载了多少
// didReceiveData : 这个方法的调用平率是很高的,那么就要注意,不要写复杂的代码,不要在主线程
// 服务器是一点儿一点儿的发送,我们客户端就一点儿一点儿的接收
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // 累加文件的大小
    self.currentTotalLength += data.length;
    
    // 计算进度
    float progress = (float)self.currentTotalLength / self.expectedLength;
    NSLog(@"进度 %f",progress);
    
    // 一点儿一点儿的保存二进制数据到dataM
    // 4.注入二进制
    [self.stream write:data.bytes maxLength:data.length];
}

/// 监听文件是否下载完成
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"文件下载结束");
    
    // 5.关闭
    [self.stream close];
}

/// 监听文件是否下载错误
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"错误信息 %@",error);
}

@end
