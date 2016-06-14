//
//  UIImageView+TDCache.m
//  TDImageLoader
//
//  Created by TudouDong on 16/6/4.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import "UIImageView+TDCache.h"
#import "UIView+TDCacheOperation.h"

@implementation UIImageView (TDCache)

- (void)d_setImageWithURl:(NSURL *)url{
    
    [self d_setImageWithURl:url placeholderImage:nil options:0 progress:nil complete:nil];
}

- (void)d_setImageWithURl:(NSURL *)url
         placeholderImage:(UIImage *)placeholder{
    
    [self d_setImageWithURl:url placeholderImage:placeholder options:0 progress:nil complete:nil];
}

- (void)d_setImageWithURl:(NSURL *)url
         placeholderImage:(UIImage *)placeholder
                  options:(TDImageOptions)options{
    
    [self d_setImageWithURl:url placeholderImage:placeholder options:options progress:nil complete:nil];
}

- (void)d_setImageWithURl:(NSURL *)url
         placeholderImage:(UIImage *)placeholder
                  options:(TDImageOptions)options
                 progress:(TDImageDownloaderProgressBlock)progressBlock
                 complete:(TDImageCompleteBlock)completeBlock{
    
    [self cancelCurrentImageLoad];
    
    dispatch_main_async_safe(^{
        self.image = placeholder;
    });
    
    
    if (url) {
        __weak typeof(self) weakSelf = self;
       
       id<TDImagOperationProtocol> operation = [[TDImageManager shareManager]downloadImageWithURL:url options:options progress:progressBlock complete:^(UIImage *image, NSError *error, TDImageCacheType cacheType, BOOL isfinished, NSURL *imageURL) {
           if (!weakSelf) {
               return ;
           }
           
           dispatch_main_sync_safe(^{
           
               if (!weakSelf) {
                   return ;
               }
               if (image) {
                   weakSelf.image = image;
                   [weakSelf setNeedsLayout];
                   
               }else{
                   weakSelf.image = placeholder;
                   [weakSelf setNeedsLayout];
               }
               
               if (completeBlock && isfinished) {
                   completeBlock(image,error,cacheType,imageURL);
               }
               
           });
           
        }];
        
        [self d_setImageLoadOperation:operation forKey:@"UIImageViewTDLoader"];
        
    }else{
        
        dispatch_main_async_safe(^{
            NSError *error = [NSError errorWithDomain:TDImageErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
            if (completeBlock) {
                completeBlock(nil, error, TDImageCacheTypeNone, url);
            }
        });
        
    }
    
    
    
    
}


- (void)cancelCurrentImageLoad{
    [self d_cancelImageLoadOperationForKey:@"UIImageViewTDLoader"];
}








@end
