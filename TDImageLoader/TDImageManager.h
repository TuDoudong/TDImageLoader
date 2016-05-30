//
//  TDImageManager.h
//  TDImageLoader
//
//  Created by 董慧翔 on 16/5/27.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDImageCache.h"
#import "TDImageDownloader.h"
#import "TDImageDownloaderOperation.h"
#import "TDImagOperationProtocol.h"

#define dispatch_main_sync_safe(block)\
if ([NSThread isMainThread]) {\
    block();\
} else {\
    dispatch_sync(dispatch_get_main_queue(), block);\
}

#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
    block();\
} else {\
    dispatch_async(dispatch_get_main_queue(), block);\
}



typedef NS_OPTIONS(NSUInteger, TDImageOptions) {
    TDImageRetryFailed = 1 << 0,
    TDImageCacheMemoryOnly = 1 << 1,
    TDImageRefreshCache = 1 << 2,
};

typedef void(^TDImageDownloaderCompleteFinishedBlock)(UIImage *image, NSError *error, TDImageCacheType cacheType, BOOL isfinished, NSURL *imageURL);

@interface TDImageManager : NSObject

@property (nonatomic,strong,readonly)TDImageCache *imageCache;
@property (nonatomic,strong,readonly)TDImageDownloader *downloader;


+(instancetype)shareManager;

- (id<TDImagOperationProtocol>)downloadImageWithURL:(NSURL *)url
                     options:(TDImageOptions)options
                    progress:(TDImageDownloaderProgressBlock)progressBlock
                    complete:(TDImageDownloaderCompleteFinishedBlock)comlpleteBlock;




@end
