//
//  TDImageCache.h
//  TDImageCache
//
//  Created by 董慧翔 on 16/5/16.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger, TDImageCacheType) {
    
    TDImageCacheTypeNone,
    
    TDImageCacheTypeDisk,
    
    TDImageCacheTypeMemory
};

typedef void(^TDImageQueryCompletBlock)(UIImage *image ,TDImageCacheType cacheType);

@interface TDImageCache : NSObject

@property (assign, nonatomic) BOOL shouldCacheImagesInMemory;

+(TDImageCache *)shareImageCache;

- (void)storeImage:(NSURL *)location forKey:(NSString *)key toDisk:(BOOL)toDisk;

- (NSOperation *)queryDiskCacheForKey:(NSString *)key done:(TDImageQueryCompletBlock)doneBlock;

@end
