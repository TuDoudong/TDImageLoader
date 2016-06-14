//
//  UIView+TDCacheOperation.m
//  TDImageLoader
//
//  Created by 董慧翔 on 16/6/5.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import "UIView+TDCacheOperation.h"
#import "TDImageManager.h"
#import <objc/runtime.h>

@implementation UIView (TDCacheOperation)


- (NSMutableDictionary *)operationsDictionary{
     NSMutableDictionary *operations = objc_getAssociatedObject(self, _cmd);
    if (!operations) {
        objc_setAssociatedObject(self, _cmd, [NSMutableDictionary dictionary], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return  objc_getAssociatedObject(self, _cmd);;
}

- (void)d_setImageLoadOperation:(id)operation forKey:(NSString *)key{
    [self d_cancelImageLoadOperationForKey:key];
    
    NSMutableDictionary *operationDictionary = self.operationsDictionary;
    [operationDictionary setObject:operation forKey:key];
    
}

- (void)d_cancelImageLoadOperationForKey:(NSString *)key{
    NSMutableDictionary *operationDictionary = self.operationsDictionary;
    id operations = [operationDictionary objectForKey:key];
    if (operations) {
        
        if ([operations isKindOfClass:[NSArray class]]) {
            for (id<TDImagOperationProtocol>operation in operations) {
                if (operation) {
                   [operation cancel];
                }
            }
        }else if ([operations conformsToProtocol:@protocol(TDImagOperationProtocol)]){
            [(id<TDImagOperationProtocol>)operations cancel];
        }
        
        [operationDictionary removeObjectForKey:key];
    }
}

@end
