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
@property (nonatomic,copy) TDImageCallBackBlock cancelBlock;

@property (nonatomic,strong) NSURLSessionDataTask *downDataTask;
@property (nonatomic,strong) NSURLSession *downloadSession;
@property (nonatomic,strong) NSMutableData *imageData;

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
@end

@implementation TDImageDownloaderOperation
@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithRequest:(NSURLRequest *)request options:(TDImageDownLoderOptions)options progress:(TDImageDownloaderProgressBlock)progressBlock completed:(TDImageDownloaderCompleteBlock)completeBlock{
    if (self = [super init]) {
        _request = request;
        _options = options;
        _progressBlock = [progressBlock copy];
        _completeBlock = [completeBlock copy];
        _finished = NO;
        _executing = NO;
    }
    return self;
}

- (void)start{
    
    
    
    @synchronized (self) {
        
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }
        
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.downloadSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
        
        self.downDataTask = [self.downloadSession dataTaskWithRequest:self.request];
        self.executing = YES;
    }
    
    
    [self.downDataTask resume];
    [self.downloadSession finishTasksAndInvalidate];
    
    if (self.downDataTask) {
        if (self.progressBlock) {
            self.progressBlock(0, NSURLResponseUnknownLength);
        }
        
        CFRunLoopRun();
        
        if (!self.isFinished) {
            [self.downDataTask cancel];
            [self URLSession:self.downloadSession task:self.downDataTask didCompleteWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:@{NSURLErrorFailingURLErrorKey : self.request.URL}]];
            
        }

    }else{
        if (self.completeBlock) {
            self.completeBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Connection can't be initialized"}], YES);
        }
    }
    
}

- (void)done{
    self.executing = NO;
    self.finished = YES;
    [self reset];
}

- (void)reset {
    self.cancelBlock = nil;
    self.completeBlock = nil;
    self.progressBlock = nil;
    
    self.imageData = nil;
    
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent {
    return YES;
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




