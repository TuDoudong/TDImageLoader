//
//  TDImageDownloaderOperation.h
//  TDImageCache
//
//  Created by 董慧翔 on 16/5/13.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TDImageDownloader.h"
@interface TDImageDownloaderOperation : NSOperation

@property (strong, nonatomic, readonly) NSURLRequest *request;



- (instancetype)initWithRequest:(NSURLRequest *)request;
@end
