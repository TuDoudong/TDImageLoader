//
//  TDImageDownloaderOperation.m
//  TDImageCache
//
//  Created by TudouDong on 16/5/13.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import "TDImageDownloaderOperation.h"

@interface TDImageDownloaderOperation ()<NSURLSessionDataDelegate>

@property (nonatomic,copy) TDImageDownloaderProgressBlock progressBlock;
@property (nonatomic,copy) TDImageDownloaderCompleteBlock completeBlock;

@property (nonatomic,strong) NSURLSessionDataTask *downDataTask;
@property (nonatomic,strong) NSURLSession *downloadSession;
@property (strong, nonatomic) NSMutableData *imageData;
@end

@implementation TDImageDownloaderOperation


- (instancetype)initWithRequest:(NSURLRequest *)request options:(TDImageDownLoderOptions)options progress:(TDImageDownloaderProgressBlock)progressBlock completed:(TDImageDownloaderCompleteBlock)completeBlock{
    if (self = [super init]) {
        _request = request;
        _options = options;
        _progressBlock = [progressBlock copy];
        _completeBlock = [completeBlock copy];
    }
    return self;
}

- (void)start{
    
    
    
    @synchronized (self) {
        
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.downloadSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
        
        self.downDataTask = [self.downloadSession dataTaskWithRequest:self.request];
    }
    
    
    [self.downDataTask resume];
    
    [self.downloadSession finishTasksAndInvalidate];
    
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    
    
    NSInteger expected = response.expectedContentLength > 0 ? (NSInteger)response.expectedContentLength : 0;
    self.expectedSize = expected;
    if (self.progressBlock) {
        self.progressBlock(0, expected);
    }
    
    self.imageData = [[NSMutableData alloc] initWithCapacity:expected];
    completionHandler(NSURLSessionResponseAllow);
    
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    [self.imageData appendData:data];
    
    if (self.progressBlock) {
        self.progressBlock(self.imageData.length,self.expectedSize);
    }
    
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    TDImageDownloaderCompleteBlock completeBlock = self.completeBlock;
    
    
    if (completeBlock) {
        if (self.imageData) {
            UIImage *image = [UIImage imageWithData:self.imageData];
            
            self.completeBlock(image,self.imageData,nil,YES);
        }
        
    }
    
    self.completeBlock = nil;
    
}



















@end




