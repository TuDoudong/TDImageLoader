//
//  TDImageCache.h
//  TDImageCache
//
//  Created by TudouDong on 16/5/16.
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

@property (nonatomic,assign) NSInteger maxCachePeriod;

/**
 *  最大缓存size 默认关闭 需要用户手动开启
 */
@property (nonatomic,assign) NSUInteger maxCacheSize;




+(TDImageCache *)shareImageCache;



- (void)storeImge:(UIImage *)image imageData:(NSData*)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk;



/**
 *  以给定的key 异步的取得对应的image
 *
 *  @param key       储存image 的key
 */
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
 *  缓存过期 或者超过maxCacheSize（默认关闭此功能，需用户手动设置） 清除部分缓存
 *
 *  @param complteBlock 执行完成回调block
 */
- (void)cleanExpiredDiskWithCompleteBlock:(void(^)())complteBlock;


/**
 *  缓存过期 或者超过maxCacheSize（默认关闭此功能，需用户手动设置） 清除部分缓存
 */
- (void)cleanExpiredDisk;



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
