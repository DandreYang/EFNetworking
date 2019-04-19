//
//  NSDictionary+EFNetworking.h
//  EFNetworking
//
//  Created by Dandre on 2018/4/4.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (EFNetworking)

/**
 转换为URL参数

 @return URL参数
 */
- (NSString *)efn_toURLQuery;

/**
 转换为JSON字符串

 @return JSON字符串
 */
- (NSString *)efn_toJSONString;

/**
 把对象（object）转换成字典
 
 @param object 模型对象
 @return 返回字典
 */
+ (NSDictionary *)efn_dictionaryWithObject:(NSObject *)object;

@end

@interface NSMutableDictionary (EFNetworking)


/**
 根据协议名称删除Key为协议属性的对象

 @param protocol 协议名称
 */
- (void)efn_removeObjectsForProtocol:(Protocol *)protocol;

@end
