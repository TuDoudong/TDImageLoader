//
//  UIImage+TDMultiFormat.m
//  TDImageLoader
//
//  Created by 董慧翔 on 16/6/29.
//  Copyright © 2016年 TudouDong. All rights reserved.
//

#import "UIImage+TDMultiFormat.h"
#import "NSData+TDImageDataType.h"
#import <ImageIO/ImageIO.h>


@implementation UIImage (TDMultiFormat)

+ (UIImage *)td_imageWithData:(NSData *)data{
    if (!data) {
        return nil;
    }
    UIImage *image;
    NSString *imageContentType = [NSData sd_contentTypeForImageData:data];
    if ([imageContentType isEqualToString:@"image/gif"]) {
        
    }
    else if ([imageContentType isEqualToString:@"image/webp"])
    {
        
    }else{
        
        image = [[UIImage alloc] initWithData:data];
        if (!image) {
            return nil;
        }
        
        CGFloat imageWidth = CGImageGetWidth(image.CGImage);
        CGFloat imageHeight = CGImageGetHeight(image.CGImage);
        
        if (imageWidth >= 3000 || imageHeight >= 3000) {
            image = [self compressImageWith:image];
        }else{
            image = [self decodedImageWithImage:image];
        }
        if (!image) {
            return nil;
        }
        UIImageOrientation orientation = [self sd_imageOrientationFromImageData:data];
        if (orientation != UIImageOrientationUp) {
            image = [UIImage imageWithCGImage:image.CGImage
                                        scale:image.scale
                                  orientation:orientation];
        }

    }
    
    
    
    return image;
}



+ (UIImage *)compressImageWith:(UIImage *)sourceImage{
    
    @autoreleasepool {
        
        CGSize sourceResolution;
        CGSize destResolution;
        size_t bytesPerRow = CGImageGetBytesPerRow(sourceImage.CGImage);
        size_t bytesPerPixel = bytesPerRow / sourceResolution.width;
        size_t bitsPerComponent = CGImageGetBitsPerComponent(sourceImage.CGImage);
        CGFloat bytesPerMB = 1048576.0f;
        CGFloat pixelsPerMB = bytesPerMB/bytesPerPixel;
        CGFloat kDestImageSizeMB =  30.f;
        CGFloat destTotalPixels = kDestImageSizeMB * pixelsPerMB;
        
        sourceResolution.width = CGImageGetWidth(sourceImage.CGImage);
        sourceResolution.height = CGImageGetHeight(sourceImage.CGImage);
        
        CGFloat sourceTotalPixels = sourceResolution.width * sourceResolution.height;
        CGFloat imageScale = destTotalPixels/sourceTotalPixels;
        
        destResolution.width = (NSInteger)( sourceResolution.width * imageScale );
        destResolution.height = (NSInteger)( sourceResolution.height * imageScale );
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        NSInteger destBytesPerRow = bytesPerPixel * destResolution.width;
        void* destBitmapData = malloc( destBytesPerRow * destResolution.height );
        if( destBitmapData == NULL ) {
            return nil;
        }
        
        CGContextRef destContext = CGBitmapContextCreate( destBitmapData, destResolution.width, destResolution.height, bitsPerComponent, destBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast );
        if( destContext == NULL ) {
            free( destBitmapData );
            return nil;
        }
        CGContextTranslateCTM( destContext, 0.0f, destResolution.height );
        CGContextScaleCTM( destContext, 1.0f, -1.0f );
        
        CGImageRef sourceImageRef = CGImageCreateWithImageInRect( sourceImage.CGImage, CGRectMake(0, 0, sourceImage.size.width, sourceImage.size.height));
        CGContextDrawImage( destContext, CGRectMake(0, 0, destResolution.width, destResolution.height), sourceImageRef );
        
        CGImageRef destImageRef = CGBitmapContextCreateImage( destContext );
        UIImage *destImage = [UIImage imageWithCGImage:destImageRef scale:1.0f orientation:UIImageOrientationUpMirrored];
        
        return destImage;

    }
    
    
}



+(UIImageOrientation)sd_imageOrientationFromImageData:(NSData *)imageData {
    UIImageOrientation result = UIImageOrientationUp;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    if (imageSource) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
        if (properties) {
            CFTypeRef val;
            int exifOrientation;
            val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
            if (val) {
                CFNumberGetValue(val, kCFNumberIntType, &exifOrientation);
                result = [self sd_exifOrientationToiOSOrientation:exifOrientation];
            } // else - if it's not set it remains at up
            CFRelease((CFTypeRef) properties);
        } else {
            //NSLog(@"NO PROPERTIES, FAIL");
        }
        CFRelease(imageSource);
    }
    return result;
}
+ (UIImageOrientation) sd_exifOrientationToiOSOrientation:(int)exifOrientation {
    UIImageOrientation orientation = UIImageOrientationUp;
    switch (exifOrientation) {
        case 1:
            orientation = UIImageOrientationUp;
            break;
            
        case 3:
            orientation = UIImageOrientationDown;
            break;
            
        case 8:
            orientation = UIImageOrientationLeft;
            break;
            
        case 6:
            orientation = UIImageOrientationRight;
            break;
            
        case 2:
            orientation = UIImageOrientationUpMirrored;
            break;
            
        case 4:
            orientation = UIImageOrientationDownMirrored;
            break;
            
        case 5:
            orientation = UIImageOrientationLeftMirrored;
            break;
            
        case 7:
            orientation = UIImageOrientationRightMirrored;
            break;
        default:
            break;
    }
    return orientation;
}


+ (UIImage *)decodedImageWithImage:(UIImage *)image {
    
    @autoreleasepool{
        // do not decode animated images
        if (image.images) { return image; }
        
        CGImageRef imageRef = image.CGImage;
        
        CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
        BOOL anyAlpha = (alpha == kCGImageAlphaFirst ||
                         alpha == kCGImageAlphaLast ||
                         alpha == kCGImageAlphaPremultipliedFirst ||
                         alpha == kCGImageAlphaPremultipliedLast);
        
        if (anyAlpha) { return image; }
        
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        
        // current
        CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
        CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(imageRef);
        
        bool unsupportedColorSpace = (imageColorSpaceModel == 0 || imageColorSpaceModel == -1 || imageColorSpaceModel == kCGColorSpaceModelIndexed);
        if (unsupportedColorSpace)
            colorspaceRef = CGColorSpaceCreateDeviceRGB();
        
        CGContextRef context = CGBitmapContextCreate(NULL, width,
                                                     height,
                                                     CGImageGetBitsPerComponent(imageRef),
                                                     0,
                                                     colorspaceRef,
                                                     kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
        
        // Draw the image into the context and retrieve the new image, which will now have an alpha layer
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        CGImageRef imageRefWithAlpha = CGBitmapContextCreateImage(context);
        UIImage *imageWithAlpha = [UIImage imageWithCGImage:imageRefWithAlpha];
        
        if (unsupportedColorSpace)
            CGColorSpaceRelease(colorspaceRef);
        
        CGContextRelease(context);
        CGImageRelease(imageRefWithAlpha);
        
        return imageWithAlpha;
    }
}


@end
