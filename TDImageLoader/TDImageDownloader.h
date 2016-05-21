//
//  TDImageDownloader.h
//  TDImageCache
//
//  Created by 董慧翔 on 16/5/13.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "TDImageCache.h"
typedef void(^TDImageDownloaderProgressBlock)(NSInteger receivedSize,NSInteger expectedSize);

typedef void(^TDImageDownloaderCompleteBlock)(UIImage *image, NSData *data, NSError *error, BOOL isfinished);

typedef NSURL * (^TDURLSessionDownloadTaskDidFinishDownloadingBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location);

@interface TDImageDownloader : NSObject


@property (nonatomic,strong,readonly)TDImageCache *imageCache;

+(TDImageDownloader *)shareDownloader;



-(void)downloadImageFrom:(NSURL *)url
                progress:(TDImageDownloaderProgressBlock)progressBlock
                complete:(TDImageDownloaderCompleteBlock)completedBlock;

@end
