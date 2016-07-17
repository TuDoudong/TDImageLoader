//
//  TDImageDownloader.h
//  TDImageCache
//
//  Created by TudouDong on 16/5/13.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TDImagOperationProtocol.h"


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


@property (assign, nonatomic) NSTimeInterval downloadTimeout;

+(TDImageDownloader *)shareDownloader;

- (id<TDImagOperationProtocol>)downloadImageWithURL:(NSURL *)url
                     options:(TDImageDownLoderOptions)options
                    progress:(TDImageDownloaderProgressBlock)progressBlock
                    complete:(TDImageDownloaderCompleteBlock)completedBlock;


@end
