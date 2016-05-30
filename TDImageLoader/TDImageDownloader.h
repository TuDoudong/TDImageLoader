//
//  TDImageDownloader.h
//  TDImageCache
//
//  Created by 董慧翔 on 16/5/13.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TDImagOperationProtocol.h"
#import "TDImageCache.h"

static NSString *const ProgressCallbackKey = @"progress";
static NSString *const CompletedCallbackKey = @"completed";

typedef NS_OPTIONS(NSUInteger, TDImageDownLoderOptions) {
    TDImageDownLoderDefalt = 1 << 0,
    TDImageDownLoderBackground = 1 << 1,
};

typedef NS_ENUM(NSInteger,TDImageDownLoaderExecutionOder) {
    TDImageDownloaderFIFOExecutionOrder,
    TDImageDownloaderLIFOExecutionOrder
};

typedef void(^TDImageCallBackBlock)();


typedef void(^TDImageDownloaderProgressBlock)(NSInteger receivedSize,NSInteger expectedSize);

typedef void(^TDImageDownloaderCompleteBlock)(UIImage *image, NSData *data, NSError *error, BOOL isfinished);

typedef NSURL * (^TDURLSessionDownloadTaskDidFinishDownloadingBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location);

@interface TDImageDownloader : NSObject


@property (nonatomic,strong,readonly)TDImageCache *imageCache;

+(TDImageDownloader *)shareDownloader;

@property (assign, nonatomic) NSTimeInterval downloadTimeout;


-(void)downloadImageFrom:(NSURL *)url
                progress:(TDImageDownloaderProgressBlock)progressBlock
                complete:(TDImageDownloaderCompleteBlock)completedBlock;

- (id<TDImagOperationProtocol>)downloadImageWithURL:(NSURL *)url
                     options:(TDImageDownLoderOptions)options
                    progress:(TDImageDownloaderProgressBlock)progressBlock
                    complete:(TDImageDownloaderCompleteBlock)completedBlock;


@end
