//
//  ViewController.m
//  breakpointDownloading
//
//  Created by kenen on 2017/3/20.
//  Copyright © 2017年 kenen. All rights reserved.
//

#import "ViewController.h"
#import "DownloadFile.h"

@interface ViewController ()

@property (nonatomic, strong) DownloadFile *downloader;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //下载按钮
    UIButton *downloadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    downloadBtn.backgroundColor = [UIColor blueColor];
    downloadBtn.frame = CGRectMake(50, 50, 100, 40);
    [downloadBtn setTitle:@"下 载" forState:UIControlStateNormal];
    [downloadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    downloadBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [downloadBtn addTarget:self action:@selector(downloadBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:downloadBtn];
    
    //暂停按钮
    UIButton *pauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    pauseBtn.backgroundColor = [UIColor greenColor];
    pauseBtn.frame = CGRectMake(170, 50, 100, 40);
    [pauseBtn setTitle:@"暂 停" forState:UIControlStateNormal];
    [pauseBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    pauseBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [pauseBtn addTarget:self action:@selector(pauseBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pauseBtn];
    
}

//下载按钮点击事件
- (void)downloadBtnClick:(UIButton *)btn {
    
    // 创建文件下载的对象
    DownloadFile *downloader = [[DownloadFile alloc] init];
    self.downloader = downloader;
    
    // 调用对象方法实现文件的下载
    [downloader downloadFileURLString:@"文件地址"];
    
}

//暂停按钮点击事件
- (void)pauseBtnClick:(UIButton *)btn {
    
    [self.downloader pauseDownload];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
