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


- (void)storeImge:(UIImage *)image imageData:(NSData*)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk;


- (NSOperation *)queryDiskCacheForKey:(NSString *)key done:(TDImageQueryCompletBlock)doneBlock;


/**
 *  清除对应url的图片
 *
 *  @param key 图片url
 */
- (void)removeImageForKey:(NSString *)key;

/**
 *  清除所有的内存图片缓存
 */
- (void)clearAllMemory;

/**
 *  清除所有的磁盘图片缓存
 */
- (void)clearAllDisk;

/**
 *  获取图片的存储地址
 *
 *  @param key 图片的url
 *
 *  @return 图片存储地址
 */
- (NSString *)defaultCachePathForKey:(NSString *)key;

/**
 *  获取磁盘缓存全部图片的size
 *
 *  @return 缓存图片的size
 */
- (NSUInteger)getDiskSize;


@end
