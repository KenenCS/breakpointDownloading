//
//  DownloadFile.h
//  07-文件下载
//
//  Created by Apple on 16/6/5.
//  Copyright © 2016年 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadFile : NSObject

/// 文件下载的主方法
- (void)downloadFileURLString:(NSString *)URLString;

/// 暂停下载
- (void)pauseDownload;

@end
