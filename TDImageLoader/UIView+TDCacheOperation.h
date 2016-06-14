//
//  UIView+TDCacheOperation.h
//  TDImageLoader
//
//  Created by 董慧翔 on 16/6/5.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface UIView (TDCacheOperation)

@property (nonatomic,readonly) NSMutableDictionary *operationsDictionary;

- (void)d_setImageLoadOperation:(id)operation forKey:(NSString *)key;
- (void)d_cancelImageLoadOperationForKey:(NSString *)key;

@end
