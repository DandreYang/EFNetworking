//
//  EFNetProxy.h
//  EFNetworking
//
//  Created by Dandre on 2018/3/23.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EFNRequest.h"
#import "EFNResponse.h"

/**
 * 网络请求处理类（代理网关）
 *
 * 用于处理相关请求和响应
 */
@interface EFNetProxy : NSObject

/**
 是否支持HTTPS， 默认支持 YES
 */
@property (nonatomic, assign) BOOL enableHTTPS;

/**
 是否验证域名 默认 NO
 */
@property (nonatomic, assign) BOOL validatesDomainName;

/**
 是否支持过期的证书 默认 YES
 */
@property (nonatomic, assign) BOOL allowInvalidCertificates;

/**
 单例

 @return 单例对象
 */
+ (instancetype _Nonnull )shareProxy;

/**
 快捷实例化一个新的网关对象方法
 
 @return 新的对象
 */
+ (instancetype _Nonnull )newProxy;

/**
 当前网络状态 -1:未知，0:无网络 1:蜂窝网络 2:WiFi

 @return return value description
 */
- (EFNReachableStatus)reachabilityStatus;

/**
 添加SSL证书

 @param cert 证书数据
 */
- (void)addSSLPinningCert:(NSData *_Nonnull)cert;

/**
 获取指定请求的DataTask

 @param requestID 请求ID
 @return return value description
 */
- (__kindof NSURLSessionTask *_Nullable)taskForRequestID:(NSNumber *_Nonnull)requestID;

/**
 聚合请求数据

 @param request 请求的request
 @param successBlock 成功的回调
 @param failureBlock 失败的回调
 @return 队列编号
 */
- (NSNumber *_Nonnull)request:(EFNRequest * _Nonnull)request
               uploadProgress:(EFNProgressBlock _Nullable)uploadProgressBlock
             downloadProgress:(EFNProgressBlock _Nullable)downloadProgressBlock
                      success:(EFNCallBlock _Nullable )successBlock
                      failure:(EFNCallBlock _Nullable )failureBlock;

#pragma mark - Resume Methods
/**
 继续所有请求
 */
- (void)resumeAllRequests;

/**
 继续指定请求
 
 @param requestID 请求ID
 */
- (void)resumeWithRequestID:(NSNumber *_Nonnull)requestID;

/**
 批量继续请求
 
 @param requestIDList 请求的ID集合
 */
- (void)resumeWithRequestIDList:(NSArray <NSNumber *> *_Nonnull)requestIDList;

#pragma mark - Suspend Methods
/**
 暂停所有请求
 */
- (void)suspendAllRequests;

/**
 暂停指定请求

 @param requestID 请求ID
 */
- (void)suspendWithRequestID:(NSNumber *_Nonnull)requestID;
/**
 批量暂停请求
 
 @param requestIDList 请求的ID集合
 */
- (void)suspendWithRequestIDList:(NSArray <NSNumber *> *_Nonnull)requestIDList;

#pragma mark - Cancel Methods
/**
 取消所有请求
 */
- (void)cancelAllRequests;

/**
 取消指定请求
 
 @param requestID 请求的ID
 */
- (void)cancelWithRequestID:(NSNumber *_Nonnull)requestID;

/**
 批量取消请求
 
 @param requestIDList 请求的ID集合
 */
- (void)cancelWithRequestIDList:(NSArray <NSNumber *> *_Nonnull)requestIDList;

@end
