//
//  TDImageManager.h
//  TDImageLoader
//
//  Created by TudouDong on 16/5/27.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TDImageCache.h"
#import "TDImageDownloader.h"
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
extern NSString *const TDImageErrorDomain;

typedef NS_OPTIONS(NSUInteger, TDImageOptions) {
    TDImageRetryFailed = 1 << 0,
    TDImageCacheMemoryOnly = 1 << 1,
    TDImageRefreshCache = 1 << 2,
};

typedef void(^TDImageCompleteFinishedBlock)(UIImage *image, NSError *error, TDImageCacheType cacheType, BOOL isfinished, NSURL *imageURL);

typedef void(^TDImageCompleteBlock)(UIImage *image, NSError *error, TDImageCacheType cacheType, NSURL *imageURL);





@interface TDImageManager : NSObject

@property (nonatomic,strong,readonly)TDImageCache *imageCache;
@property (nonatomic,strong,readonly)TDImageDownloader *downloader;


+(instancetype)shareManager;


- (id<TDImagOperationProtocol>)downloadImageWithURL:(NSURL *)url
                     options:(TDImageOptions)options
                   cacheType:(TDImageCacheType)cacheType
                    progress:(TDImageDownloaderProgressBlock)progressBlock
                    complete:(TDImageCompleteFinishedBlock)comlpleteBlock;




@end
