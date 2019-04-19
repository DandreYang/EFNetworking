//
//  NSString+EFNetworking.h
//  EFNetworking
//
//  Created by Dandre on 2018/4/10.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (EFNetworking)

/**
 MD5 32位加密
 */
- (NSString *)efn_MD5_32_Encode;

/**
 MD5 16位加密
 */
- (NSString *)efn_MD5_16_Encode;

/**
 HmacSHA1加密，并以Base64位字符串返回；
 */
- (NSString *)efn_HmacSha1WithKey:(NSString *)key;

/**
 HmacSHA256加密, 并以十六进制字符串返回；
 */
- (NSString *)efn_HmacSha256WithKey:(NSString *)key;

@end
