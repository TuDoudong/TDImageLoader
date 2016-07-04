//
//  NSData+TDImageDataType.h
//  TDImageLoader
//
//  Created by 董慧翔 on 16/6/29.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (TDImageDataType)
+ (NSString *)sd_contentTypeForImageData:(NSData *)data;
@end
