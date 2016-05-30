//
//  TDImageManager.m
//  TDImageLoader
//
//  Created by 董慧翔 on 16/5/27.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import "TDImageManager.h"


@interface TDImageCombinedOperation : NSObject <TDImagOperationProtocol>

@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;

@property (strong, nonatomic) NSOperation *cacheOperation;

@end



@interface TDImageManager ()
@property (strong, nonatomic) NSMutableSet *failedURLs;
@property (strong, nonatomic) NSMutableArray *runningOperations;


@end
@implementation TDImageManager

+(instancetype)shareManager{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}
-(instancetype)init{
    if (self = [super init]) {
        _imageCache = [TDImageCache shareImageCache];
        _downloader = [TDImageDownloader shareDownloader];
        _failedURLs = [NSMutableSet set];
        _runningOperations = [NSMutableArray array];
    }
    return self;
}
- (id<TDImagOperationProtocol>)downloadImageWithURL:(NSURL *)url
                     options:(TDImageOptions)options
                    progress:(TDImageDownloaderProgressBlock)progressBlock
                    complete:(TDImageDownloaderCompleteFinishedBlock)comlpleteBlock{
    
    if ([url isKindOfClass:[NSString class]]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
    
    if (![url isKindOfClass:[NSURL class]]) {
        url = nil;
    }
    
    
    
    BOOL isFailURL = NO;
    @synchronized (self.failedURLs) {
        isFailURL = [self.failedURLs containsObject:url];
    }
    
    __block  TDImageCombinedOperation *Operation = [[TDImageCombinedOperation alloc]init];
    
    __weak TDImageCombinedOperation *weakOperation = Operation;
    
    @synchronized (self.runningOperations) {
        [self.runningOperations addObject:Operation];
    }
    
    Operation.cacheOperation = [self.imageCache queryDiskCacheForKey:url.absoluteString done:^(UIImage *image, TDImageCacheType cacheType) {
        if (Operation.isCancelled) {
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:Operation];
            }
        }
        
        if (!image || options & TDImageRefreshCache) {
            
            if (image && options & TDImageRefreshCache) {
                dispatch_main_sync_safe(^{
                    comlpleteBlock(image,nil,cacheType,YES,url);
                });
            }
            
            id <TDImagOperationProtocol> subOperation = [self.downloader downloadImageWithURL:url options:TDImageDownLoderDefalt progress:progressBlock complete:^(UIImage *image, NSData *data, NSError *error, BOOL isfinished) {
                if (error) {
                    dispatch_main_sync_safe(^{
                        if (!weakOperation.isCancelled) {
                            comlpleteBlock(nil,error,TDImageCacheTypeNone,YES,url);
                        }
                        
                        @synchronized (self.failedURLs) {
                            [self.failedURLs addObject:url];
                        }
                        
                    });
                    
                }else if (weakOperation.isCancelled){
                
                }else{
                    
                }
                
                
            }];
            
            
            

            
        }else if(image){
            dispatch_main_sync_safe(^{
                if (!weakOperation.isCancelled) {
                    comlpleteBlock(image,nil,cacheType,YES,url);
                }
            });
            
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:Operation];
            }
            
        }else{
            dispatch_main_sync_safe(^{
                if (!weakOperation.isCancelled) {
                    comlpleteBlock(nil,nil,TDImageCacheTypeNone,YES,url);
                }
            });
            
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:Operation];
            }
        }
        
        
    }];
    
    return Operation;
    
}


@end
