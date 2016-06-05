//
//  UIImageView+TDCache.h
//  TDImageLoader
//
//  Created by TudouDong on 16/6/4.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDImageManager.h"
@interface UIImageView (TDCache)
- (void)d_setImageWithURl:(NSURL *)url;
- (void)d_setImageWithURl:(NSURL *)url placeholderImage:(UIImage *)placeholder;
- (void)d_setImageWithURl:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(TDImageOptions)options;


- (void)d_setImageWithURl:(NSURL *)url
         placeholderImage:(UIImage *)placeholder
                  options:(TDImageOptions)options
                 progress:(TDImageDownloaderProgressBlock)progressBlock
                 complete:(TDImageCompleteBlock)completeBlock;

@end
