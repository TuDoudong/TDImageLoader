//
//  ViewController.m
//  TDImageLoader
//
//  Created by 董慧翔 on 16/5/21.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import "ViewController.h"

#import "TDImageDownloaderOperation.h"
#import "TDImageDownloader.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    TDImageDownloader *downloader = [TDImageDownloader shareDownloader];
    
    [downloader downloadImageFrom:[NSURL URLWithString:@"http://guidemark-img.b0.upaiyun.com/EruviTOL3e.jpg"] progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        NSLog(@"receivedSize :%ld",receivedSize);
        NSLog(@"expectedSize : %ld",expectedSize);
        
        
    } complete:^(UIImage *image, NSData *data, NSError *error, BOOL isfinished) {
        
    }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
