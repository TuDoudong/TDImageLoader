//
//  UIImage+TDMultiFormat.h
//  TDImageLoader
//
//  Created by 董慧翔 on 16/6/29.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (TDMultiFormat)



+ (UIImage *)td_imageWithData:(NSData *)data;

+ (UIImage *)compressImageWith:(UIImage *)sourceImage;
@end
