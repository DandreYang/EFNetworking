//
//  EFNCacheHelper.h
//  EFNetworking
//
//  Created by Dandre on 2018/4/9.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EFNRequest.h"
#import "EFNResponse.h"

/**
 网络层缓存管理器
 */
@interface EFNCacheHelper : NSObject

- (instancetype _Nonnull)init NS_UNAVAILABLE;
+ (instancetype _Nonnull)new NS_UNAVAILABLE;

/**
 网络缓存单例

 @return 单例对象
 */
+ (instancetype _Nonnull )shared;

/**
 设置网络缓存

 @param response EFNResponse对象，内部存储的有网络返回的数据
 @param request EFNRequest对象，内部存储的有请求参数
 */
- (void)saveResponse:(EFNResponse *_Nonnull)response forRequest:(EFNRequest * _Nonnull)request;

/**
 根据Request获取缓存数据

 @param request EFNRequest对象，内部存储的有请求参数
 @return EFNResponse对象，内部存储的有网络返回的数据
 */
- (EFNResponse *_Nullable)responseForRequest:(EFNRequest * _Nonnull)request;

/**
 判断是否有指定请求的缓存数据

 @param request EFNRequest对象，内部存储的有请求参数
 @return YES/NO
 */
- (BOOL)containsObjectForRequest:(EFNRequest *_Nonnull)request;

/**
 网络缓存总大小

 @return 网络缓存总大小
 */
- (NSInteger)totalCacheSize;

#pragma mark - CacheData Remove Methods

/**
 根据Request清除指定缓存（同步）

 @param request EFNRequest对象，内部存储的有请求参数
 */
- (void)removeObjectForRequest:(EFNRequest *_Nonnull)request;

/**
 根据Request清除指定缓存（异步）

 @param request EFNRequest对象，内部存储的有请求参数
 @param block 清除成功后的回调
 */
- (void)removeObjectForRequest:(EFNRequest *_Nonnull)request withBlock:(nullable void(^)(NSString * _Nonnull key))block;

/**
 清除所有网络缓存 (同步)
 */
- (void)removeAllObjects;

/**
 清除所有网络缓存 (异步)

 @param block 清除成功后的回调
 */
- (void)removeAllObjectsWithBlock:(void(^_Nullable)(void))block;

/**
 清除所有网络缓存 (异步)

 @param progress 清除进度回调
 @param end 清除结束后的回调
 */
- (void)removeAllObjectsWithProgressBlock:(nullable void(^)(int removedCount, int totalCount))progress
                                 endBlock:(nullable void(^)(BOOL error))end;

@end
