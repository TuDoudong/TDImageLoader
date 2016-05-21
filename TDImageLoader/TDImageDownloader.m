//
//  TDImageDownloader.m
//  TDImageCache
//
//  Created by 董慧翔 on 16/5/13.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import "TDImageDownloader.h"

@interface TDImageDownloader ()<NSURLSessionDownloadDelegate>

@property (nonatomic,copy) TDImageDownloaderProgressBlock progrssBlock;

@property (nonatomic,strong) NSURLSessionDownloadTask *downTask;
@property (nonatomic,strong) NSURLSession *downloadSession;
@property (readwrite, nonatomic, copy) TDURLSessionDownloadTaskDidFinishDownloadingBlock downloadTaskDidFinishDownloading;
@property (nonatomic,strong) NSURL *downURL;

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
