//
//  TDImageDownloader.m
//  TDImageCache
//
//  Created by 董慧翔 on 16/5/13.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import "TDImageDownloader.h"
#import "TDImageDownloaderOperation.h"

@interface TDImageDownloader ()<NSURLSessionDownloadDelegate>

@property (nonatomic,copy) TDImageDownloaderProgressBlock progrssBlock;

@property (nonatomic,strong) NSURLSessionDownloadTask *downTask;
@property (nonatomic,strong) NSURLSession *downloadSession;
@property (readwrite, nonatomic, copy) TDURLSessionDownloadTaskDidFinishDownloadingBlock downloadTaskDidFinishDownloading;
@property (nonatomic,strong) NSURL *downURL;


@property (nonatomic,strong) NSMutableDictionary*callBackDics;
@property (nonatomic,strong) dispatch_queue_t barrierQueue;
@property (nonatomic,strong) NSOperationQueue *downloadQueue;
@property (nonatomic,assign) TDImageDownLoaderExecutionOder executOrder;
@property (weak, nonatomic) NSOperation *lastAddedOperation;

@property (nonatomic,assign) Class operationClass;

@end

@implementation TDImageDownloader

+(TDImageDownloader *)shareDownloader{
    static id instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    
    return instance;
}

- (instancetype)init{
    if (self = [super init]) {
        _imageCache = [TDImageCache shareImageCache];
        _downloadQueue = [[NSOperationQueue alloc]init];
        _downloadQueue.maxConcurrentOperationCount = 6;
        _executOrder = TDImageDownloaderFIFOExecutionOrder;
        _operationClass = [TDImageDownloaderOperation class];
        
        _barrierQueue = dispatch_queue_create("com.tudoudong.TDImageLoaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

-(void)downloadImageFrom:(NSURL *)url
                progress:(TDImageDownloaderProgressBlock)progressBlock
                complete:(TDImageDownloaderCompleteBlock)completedBlock{
    
    if (!url || url == (id)kCFNull) {
        return;
    }
    
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
    
    // Prevents app crashing on argument type error like sending NSNull instead of NSURL
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }
    
    
    NSOperation *operation = [self.imageCache queryDiskCacheForKey:url.absoluteString done:^(UIImage *image, TDImageCacheType cacheType) {
        if (operation.isCancelled) {
            return ;
        }
        
        if (image && cacheType) {
            completedBlock(image,nil,nil,YES);
        }else{
            
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            self.downloadSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue new]];
            self.downURL = url;
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            self.downTask = [self.downloadSession downloadTaskWithRequest:request];
            [self.downTask resume];
        
        }
        
        
    }];
    
    
    progressBlock = [self.progrssBlock copy];
    
}



- (id<TDImagOperationProtocol>)downloadImageWithURL:(NSURL *)url options:(TDImageDownLoderOptions)options progress:(TDImageDownloaderProgressBlock)progressBlock complete:(TDImageDownloaderCompleteBlock)completedBlock{
    __block TDImageDownloaderOperation *operation;
    __weak __typeof(self)weakself = self;
    
    
    [self addProgressCallback:progressBlock completedBlock:completedBlock forURL:url createCallback:^{
        NSTimeInterval timeoutInterval = weakself.downloadTimeout;
        if (timeoutInterval == 0.0) {
            timeoutInterval = 15.0;
        }
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeoutInterval];
        
        
        operation = [[weakself.operationClass alloc]initWithRequest:urlRequest options:options progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            TDImageDownloader *wkself = weakself;
            if (!wkself) {
                return ;
            }
            __block NSArray *callbackArrays;
            dispatch_sync(wkself.barrierQueue, ^{
                callbackArrays = [wkself.callBackDics[url] copy];
            });
            
            
            for (NSDictionary *callBack in callbackArrays) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    TDImageDownloaderProgressBlock progressCallback = callBack[ProgressCallbackKey];
                    if (progressCallback) {
                        progressCallback(receivedSize,expectedSize);
                    }
                });
            }
            
            
            
        } completed:^(UIImage *image, NSData *data, NSError *error, BOOL isfinished) {
            TDImageDownloader *wkself = weakself;
            if (!wkself) {
                return ;
            }
            
            __block  NSArray *callbackArray;
            dispatch_barrier_sync(wkself.barrierQueue, ^{
                callbackArray = [wkself.callBackDics[url] copy];
                if (isfinished) {
                    [wkself.callBackDics removeObjectForKey:url];
                }
            });
            
            for (NSDictionary *callback in callbackArray) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    TDImageDownloaderCompleteBlock completeCallback = callback[CompletedCallbackKey];
                    completeCallback(image,data,error,isfinished);
                });
                
                
            }
            
        } ];
        
        
        [weakself.downloadQueue addOperation:operation];
        
        if (weakself.executOrder == TDImageDownloaderLIFOExecutionOrder) {
            // Emulate LIFO execution order by systematically adding new operations as last operation's dependency
            [weakself.lastAddedOperation addDependency:operation];
            weakself.lastAddedOperation = operation;
        }

        
    }];
    
    return operation;
    
}
- (void)addProgressCallback:(TDImageDownloaderProgressBlock)progressBlock completedBlock:(TDImageDownloaderCompleteBlock)completedBlock forURL:(NSURL *)url createCallback:(TDImageCallBackBlock)createCallback {
    
    if (!url) {
        if (completedBlock) {
            completedBlock(nil,nil,nil,NO);
        }
        
        return;
    }
    
    dispatch_barrier_sync(self.barrierQueue, ^{
        BOOL first = NO;
        
        if (!self.callBackDics[url]) {
            self.callBackDics[url] = [NSMutableArray array];
            first = YES;
        }
        
        NSMutableArray *callBackArray = self.callBackDics[url];
        
        NSMutableDictionary *callBackInfos = [NSMutableDictionary dictionary];
        if (progressBlock) {
            callBackInfos[ProgressCallbackKey] = [progressBlock copy];
        }
        
        if (completedBlock) {
            callBackInfos[CompletedCallbackKey] = [completedBlock copy];
        }
        
        [callBackArray addObject:callBackInfos];
        self.callBackDics[url] = callBackArray;
        
        if (first) {
            createCallback();
        }
        
    });
    
    
    
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
    
    
    [self.imageCache storeImage:location forKey:self.downURL.absoluteString toDisk:YES];
    
        
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes{
    
}

@end
