//
//  ViewController.m
//  TDImageLoader
//
//  Created by TudouDong on 16/5/21.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import "ViewController.h"

#import "TDImageDownloaderOperation.h"
#import "TDImageDownloader.h"
#import "TDImageManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    
    TDImageManager *manage = [TDImageManager shareManager];
    [manage downloadImageWithURL:[NSURL URLWithString:@"http://guidemark-img.b0.upaiyun.com/EruviTOL3e.jpg"] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        NSLog(@"receivedSize :%ld",receivedSize);
        NSLog(@"expectedSize : %ld",expectedSize);
    } complete:^(UIImage *image, NSError *error, TDImageCacheType cacheType, BOOL isfinished, NSURL *imageURL) {
        
    }];
    
    
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
