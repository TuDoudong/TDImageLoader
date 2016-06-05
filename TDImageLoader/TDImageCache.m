//
//  TDImageCache.m
//  TDImageCache
//
//  Created by TudouDong on 16/5/16.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import "TDImageCache.h"

#import <CommonCrypto/CommonDigest.h>


@interface TDAutoCleanCache : NSCache

@end

@implementation TDAutoCleanCache

-(instancetype)init{
    if (self = [super init]) {
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

@end

@interface TDImageCache ()

@property (nonatomic,strong) NSString *diskCachePath;

@property (nonatomic,strong) NSCache *memCache;
@property (nonatomic,strong) dispatch_queue_t ioQueue;
@property (nonatomic,strong) NSFileManager *fileManager;

@end

@implementation TDImageCache



+(TDImageCache *)shareImageCache{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}

- (instancetype)init{
    return [self initWithNameSpace:@"TDImageDefault"];
}
- (instancetype)initWithNameSpace:(NSString *)nameSpace{
    NSString *path = [self makeDiskPathWithNameSpace:nameSpace];
    return [self initWithNamespace:nameSpace diskCacheDirectory:path];
}

- (id)initWithNamespace:(NSString *)ns diskCacheDirectory:(NSString *)directory{
    if (self = [super init]) {
        
        NSString *fullNamePath = [@"com.tudoudong.TDImageCache." stringByAppendingString:ns];
        if (directory != nil) {
            _diskCachePath = [directory stringByAppendingPathComponent:fullNamePath];
        }else{
            _diskCachePath = [self makeDiskPathWithNameSpace:ns];
        }
        
        _memCache = [[TDAutoCleanCache alloc]init];
        _ioQueue = dispatch_queue_create("com.tudoudong.TDImageCache", DISPATCH_QUEUE_SERIAL);
        dispatch_sync(_ioQueue, ^{
            _fileManager = [NSFileManager defaultManager];
        });
        
    }
    return self;
}

- (NSString *)makeDiskPathWithNameSpace:(NSString *)nameSpace{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:nameSpace];

}



- (NSString *)defaultCachePathForKey:(NSString *)key{
    return [self cachePathForKey:key inCachePath:self.diskCachePath];
}

- (NSString *)cachePathForKey:(NSString *)key inCachePath:(NSString *)cachePath{
    NSString *fileName = [self cacheFileNameForKey:key];
    return [cachePath stringByAppendingPathComponent:fileName];
}

- (NSString *)cacheFileNameForKey:(NSString *)key{
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], [[key pathExtension] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", [key pathExtension]]];
    
    return filename;

}

#pragma mark - TDImageCache


- (void)storeImge:(UIImage *)image imageData:(NSData*)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk{
    
    if (self.shouldCacheImagesInMemory) {
        [self.memCache setObject:image forKey:key];
    }
    
    
    
    if (toDisk) {
        
        dispatch_async(self.ioQueue, ^{
            
            NSData *data = imageData;
            
            NSFileManager *filemanager = [NSFileManager defaultManager];
            
            if (![filemanager fileExistsAtPath:_diskCachePath]) {
                [filemanager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
            }
            
            NSString *cachePathForKey = [self defaultCachePathForKey:key];
            [filemanager createFileAtPath:cachePathForKey contents:data attributes:nil];
            
            
        });
        
    }
    

}

- (NSOperation *)queryDiskCacheForKey:(NSString *)key done:(TDImageQueryCompletBlock)doneBlock{
    if (!doneBlock) {
        return nil;
    }
    
    if (!key) {
        return nil;
    }
    
    UIImage *image = [self imageFromMemoryCacheForKey:key];
    if (image) {
        doneBlock(image,TDImageCacheTypeMemory);
        return nil;
    }
    
    
    NSOperation *operation = [[NSOperation alloc]init];
    
    dispatch_async(self.ioQueue, ^{
        if (operation.isCancelled) {
            return ;
        }
        
        @autoreleasepool {
            
            UIImage *diskImage = [self diskImageForKey:key];
            if (diskImage && self.shouldCacheImagesInMemory) {
                [self.memCache setObject:diskImage forKey:key];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                doneBlock(diskImage ,TDImageCacheTypeDisk);
            });
        }
        
        
    });
    
    
    return operation;
}

- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key{
    return [self.memCache objectForKey:key];
}


- (UIImage *)diskImageForKey:(NSString *)key{
    NSString *cachePath = [self defaultCachePathForKey:key];
    
    NSData *data = [NSData dataWithContentsOfFile:cachePath];
    
    if (data) {
        UIImage *image = [UIImage imageWithData:data];
        return image;
    }
    
    return nil;
    
}


- (void)removeImageForKey:(NSString *)key{
    if (!key) {
        return;
    }
    NSString *cachePath = [self defaultCachePathForKey:key];
    if (self.shouldCacheImagesInMemory) {
        [self.memCache removeObjectForKey:key];
    }
    
    dispatch_async(self.ioQueue, ^{
        [self.fileManager removeItemAtPath:cachePath error:nil];
    });
    
    
}

- (void)clearAllMemory{
    
    [self.memCache removeAllObjects];
}

- (void)clearAllDisk{
    
    dispatch_async(self.ioQueue, ^{
        [self.fileManager removeItemAtPath:self.diskCachePath error:nil];
        [self.fileManager createDirectoryAtPath:self.diskCachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];
    });
    
}


- (NSUInteger)getDiskSize{
    __block NSUInteger fileSize = 0;
    
    dispatch_sync(self.ioQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskCachePath];
        for (NSString *fileName in fileEnumerator) {
            NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            fileSize += [attrs fileSize];
        }
    });
    
    return fileSize;
    
}













@end
