//
//  TDImageDownloaderOperation.m
//  TDImageCache
//
//  Created by 董慧翔 on 16/5/13.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import "TDImageDownloaderOperation.h"

@interface TDImageDownloaderOperation ()<NSURLSessionDownloadDelegate>

@property (nonatomic,copy) TDImageDownloaderProgressBlock progrssBlock;

@property (nonatomic,strong) NSURLSessionDownloadTask *downTask;
@property (nonatomic,strong) NSURLSession *downloadSession;

@end

@implementation TDImageDownloaderOperation


- (instancetype)initWithRequest:(NSURLRequest *)request{
    if (self = [super init]) {
        _request = request;
        
    }
    return self;
}

- (void)start{
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.downloadSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue new]];
    
    self.downTask = [self.downloadSession downloadTaskWithRequest:self.request];
    [self.downTask resume];
    
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    if (self.progrssBlock) {
        self.progrssBlock(totalBytesWritten,totalBytesExpectedToWrite);
    }
    
}
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
    
    
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes{

}
@end
