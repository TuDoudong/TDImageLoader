//
//  TDImageCache.m
//  TDImageCache
//
//  Created by TudouDong on 16/5/16.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import "TDImageCache.h"

#import <CommonCrypto/CommonDigest.h>
#import "UIImage+TDMultiFormat.h"

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
@property (nonatomic,strong) NSString *diskDocumentPath;
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
    NSString *cachePath = [self makeCacheDiskPathWithNameSpace:nameSpace];
    return [self initWithNamespace:nameSpace diskCacheDirectory:cachePath];
}

- (id)initWithNamespace:(NSString *)ns diskCacheDirectory:(NSString *)directory{
    if (self = [super init]) {
        
        NSString *fullNamePath = [@"com.tudoudong.TDImageCache." stringByAppendingString:ns];
        if (directory != nil) {
            _diskCachePath = [directory stringByAppendingPathComponent:fullNamePath];
        }else{
            _diskCachePath = [self makeCacheDiskPathWithNameSpace:ns];
        }
        
        NSString *documentPath = [self makeDocumentDiskPathWithNameSpace:ns];
        if (documentPath != nil) {
            _diskDocumentPath = [documentPath stringByAppendingPathComponent:fullNamePath];
        }else{
            _diskDocumentPath = documentPath;
        }
        
        
        _memCache = [[TDAutoCleanCache alloc]init];
        _ioQueue = dispatch_queue_create("com.tudoudong.TDImageCache", DISPATCH_QUEUE_SERIAL);
        dispatch_sync(_ioQueue, ^{
            _fileManager = [NSFileManager defaultManager];
        });
        
        _maxCachePeriod =  60 * 60 * 24 * 7;
        
        
        
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearAllMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanExpiredDisk)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backgroundCleanDisk)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

        
    }
    return self;
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}

- (NSString *)makeCacheDiskPathWithNameSpace:(NSString *)nameSpace{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:nameSpace];

}

- (NSString *)makeDocumentDiskPathWithNameSpace:(NSString *)nameSpace{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:nameSpace];
}



- (NSString *)defaultCachePathForKey:(NSString *)key cacheType:(TDImageCacheType)cacheType{
    if (cacheType == TDImageCacheTypeDocumentDisk){
        
        return [self cachePathForKey:key inCachePath:self.diskDocumentPath];
    }else{
        
        return [self cachePathForKey:key inCachePath:self.diskCachePath];
    }
    
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


- (void)storeImge:(UIImage *)image imageData:(NSData*)imageData forKey:(NSString *)key cacheType:(TDImageCacheType)cacheType toDisk:(BOOL)toDisk{
    
    if (self.shouldCacheImagesInMemory) {
        [self.memCache setObject:image forKey:key];
    }
    
    
    
    if (toDisk) {
        
        dispatch_async(self.ioQueue, ^{
            
            NSData *data = imageData;
            
            NSFileManager *filemanager = [NSFileManager defaultManager];
            
            
            if (cacheType == TDImageCacheTypeCacheDisk) {
                
                if (![filemanager fileExistsAtPath:_diskCachePath]) {
                    [filemanager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
                }
            }else if (cacheType == TDImageCacheTypeDocumentDisk){
                
                if (![filemanager fileExistsAtPath:self.diskDocumentPath]) {
                    [filemanager createDirectoryAtPath:self.diskDocumentPath withIntermediateDirectories:YES attributes:nil error:NULL];
                }
            }
            
            NSString *cachePathForKey = [self defaultCachePathForKey:key cacheType:cacheType];
            [filemanager createFileAtPath:cachePathForKey contents:data attributes:nil];
            
            
        });
        
    }
    

}

- (NSOperation *)queryDiskCacheForKey:(NSString *)key
                            cacheType:(TDImageCacheType)cacheType
                                 done:(TDImageQueryCompletBlock)doneBlock{
    if (!doneBlock) {
        return nil;
    }
    
    if (!key) {
        return nil;
    }
    
    if (cacheType == TDImageCacheTypeNone) {
        return nil;
    }
    
    UIImage *image = [self imageFromMemoryCacheForKey:key];
    if (image) {
        doneBlock(image,TDImageCacheTypeMemory);
        return nil;
    }
    
    if (cacheType == TDImageCacheTypeMemory) {
        return nil;
    }
    
    NSOperation *operation = [[NSOperation alloc]init];
    
    dispatch_async(self.ioQueue, ^{
        if (operation.isCancelled) {
            return ;
        }
        
        @autoreleasepool {
            
            UIImage *diskImage = [self diskImageForKey:key cacheType:cacheType];
            if (diskImage && self.shouldCacheImagesInMemory) {
                [self.memCache setObject:diskImage forKey:key];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                doneBlock(diskImage ,cacheType);
            });
        }
        
        
    });
    
    
    return operation;
}

- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key{
    return [self.memCache objectForKey:key];
}


- (UIImage *)diskImageForKey:(NSString *)key cacheType:(TDImageCacheType)cacheType{
    NSString *cachePath = [self defaultCachePathForKey:key cacheType:cacheType];
    
    NSData *data = [NSData dataWithContentsOfFile:cachePath];
    
    if (data) {
        UIImage *image = [UIImage td_imageWithData:data];
        return image;
    }
    
    return nil;
    
}


- (void)removeImageForKey:(NSString *)key{
    if (!key) {
        return;
    }
    
    NSString *cachePath = [self defaultCachePathForKey:key cacheType:TDImageCacheTypeCacheDisk];
    NSString *documentPath = [self defaultCachePathForKey:key cacheType:TDImageCacheTypeDocumentDisk];
    
    if (self.shouldCacheImagesInMemory) {
        [self.memCache removeObjectForKey:key];
    }
    
    
    
    
    dispatch_async(self.ioQueue, ^{
        [self.fileManager removeItemAtPath:cachePath error:nil];
        [self.fileManager removeItemAtPath:documentPath error:nil];
    });
    
    
}

- (void)clearAllMemory{
    
    [self.memCache removeAllObjects];
}

- (void)clearCacheDisk{
    
    dispatch_async(self.ioQueue, ^{
        [self.fileManager removeItemAtPath:self.diskCachePath error:nil];
        [self.fileManager createDirectoryAtPath:self.diskCachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];
    });
    
}

- (void)clearDocumentDick{
    
    dispatch_async(self.ioQueue, ^{
        [self.fileManager removeItemAtPath:self.diskDocumentPath error:nil];
        [self.fileManager createDirectoryAtPath:self.diskDocumentPath
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:NULL];
    });

}

- (void)cleanExpiredDisk{
    [self cleanExpiredDiskWithCompleteBlock:nil];
}


- (void)cleanExpiredDiskWithCompleteBlock:(void(^)())complteBlock{
    
    dispatch_async(self.ioQueue, ^{
        NSURL *diskCacheUrl = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
        NSArray *resourceKeys = @[NSURLIsDirectoryKey,NSURLContentModificationDateKey,NSURLTotalFileAllocatedSizeKey];
        
        NSDirectoryEnumerator *fileEnumerator =  [self.fileManager enumeratorAtURL:diskCacheUrl includingPropertiesForKeys:resourceKeys options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:NULL];
        NSDate *expiredDate = [NSDate dateWithTimeIntervalSinceNow:-self.maxCachePeriod];
        NSMutableDictionary *cacheFileDics = [NSMutableDictionary dictionary];
        NSMutableArray *deleteURLs = [NSMutableArray array];
        NSUInteger currentCacheSize = 0;
        for (NSURL *fileURL in fileEnumerator) {
            NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
            if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }
            
            NSDate *modifyDate = resourceValues[NSURLContentModificationDateKey];
            if ([[modifyDate laterDate:expiredDate] isEqualToDate:expiredDate]) {
                [deleteURLs addObject:fileURL];
                continue;
            }
            
            NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
            currentCacheSize += totalAllocatedSize.unsignedIntegerValue;
            [cacheFileDics setObject:resourceValues forKey:fileURL];
            
        }
        
        for (NSURL *fileURL in deleteURLs) {
            [self.fileManager removeItemAtURL:fileURL error:nil];
        }
        
        if (self.maxCacheSize > 0 && currentCacheSize > self.maxCacheSize) {
            const NSUInteger desiredCacheSize = self.maxCacheSize / 2;
            NSArray *soredFiles = [cacheFileDics keysSortedByValueWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                return [obj1[NSURLContentModificationDateKey] compare:obj2[NSURLContentModificationDateKey]];
            }];
            
            for (NSURL *fileURL in soredFiles) {
                if ([self.fileManager removeItemAtURL:fileURL error:nil]) {
                    NSDictionary *resourceValues = cacheFileDics[fileURL];
                    NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                    currentCacheSize -= totalAllocatedSize.unsignedIntegerValue;
                    
                    if (currentCacheSize < desiredCacheSize) {
                        break;
                    }
                    
                }
            }
            
            if (complteBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    complteBlock();
                });
            }
            
        }
        
        
    });
    
    
}


- (void)backgroundCleanDisk {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if(!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    UIApplication *application = [UIApplication performSelector:@selector(sharedApplication)];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    // Start the long-running task and return immediately.
    [self cleanExpiredDiskWithCompleteBlock:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}



- (NSUInteger)getCacheDiskSize{
    
    return [self getDiskSizeDiskPath:self.diskCachePath];
}

- (NSUInteger)getDocumentDiskSize{
    
    return [self getDiskSizeDiskPath:self.diskDocumentPath];
}

- (NSUInteger)getDiskSizeDiskPath:(NSString *)diskPath{
    
    __block NSUInteger fileSize = 0;
    
    dispatch_sync(self.ioQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:diskPath];
        for (NSString *fileName in fileEnumerator) {
            NSString *filePath = [diskPath stringByAppendingPathComponent:fileName];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            fileSize += [attrs fileSize];
        }
    });
    
    return fileSize;
}









@end
