//
//  TDImageDownloaderOperation.h
//  TDImageCache
//
//  Created by TudouDong on 16/5/13.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TDImageDownloader.h"
@interface TDImageDownloaderOperation : NSOperation<TDImagOperationProtocol>

@property (assign, nonatomic, readonly) TDImageDownLoderOptions options;


@property (strong, nonatomic, readonly) NSURLRequest *request;

@property (assign, nonatomic) NSInteger expectedSize;


- (instancetype)initWithRequest:(NSURLRequest *)request
                        options:(TDImageDownLoderOptions)options
                       progress:(TDImageDownloaderProgressBlock)progressBlock
                      completed:(TDImageDownloaderCompleteBlock)completeBlock
                         cancel:(TDImageCallBackBlock)cancelBlock;
@end
