//
//  EFNetHelper.h
//  EFNetworking
//
//  Created by Dandre on 2018/3/23.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EFNHeader.h"
#import "EFNetProxy.h"
#import "EFNCacheHelper.h"

FOUNDATION_EXPORT NSString * _Nonnull EFNetworkingDefaultDownloadDirectory(void);

/**
 * 网络请求管理类
 *
 * 用于处理一些逻辑和配置，例如管理全局网络配置、管理网络请求和网关
 */
@interface EFNetHelper : NSObject

/**
 请求服务网关 当EFNetHelper实例初始化时，会自动初始化一个该实例的请求服务网关
 */
@property (nonatomic, strong, readonly, nonnull) EFNetProxy * netProxy;

/**
 网络缓存管理器 默认缓存储存在 Library/Cache/EFNetworking/目录下
 */
@property (nonatomic, strong, readonly, nullable) EFNCacheHelper * cacheHelper;

/**
 全局配置代理, 默认的config是EFNDefaultConfig的单例
 */
@property (nonatomic, retain, nonnull) id <EFNGeneralConfigDelegate> config;

/**
 是否正在请求数据
 */
@property (nonatomic, assign, readonly) BOOL isLoading;

- (instancetype _Nonnull )init NS_UNAVAILABLE;
+ (instancetype _Nonnull )new NS_UNAVAILABLE;

/**
 网络请求助手单例

 @return 单例对象
 */
+ (instancetype _Nonnull)shareHelper;

/**
 创建并实例化一个新的网络请求助手，相当于 [[EFNetHelper alloc] init]

 @return 对象
 */
+ (instancetype _Nonnull)helper;

/**
 全局通用配置

 @param configHandler 配置回调
 */
+ (void)generalConfigHandler:(NS_NOESCAPE EFNGeneralConfigBlock _Nonnull )configHandler;

/**
 使用数据请求对象发起请求，请求对象需要遵循协议<EFNRequestModelReformer>
 @discussion 将请求参数作为请求对象的属性，适用于请求参数较多的数据交互场景，例如提交数据表单时，将表单的数据模型直接作为请求对象，同时遵循协议<EFNRequestModelReformer>后发起请求

 @param requestModel 请求模型，需要遵循EFNRequestModelReformer协议
 @param reformerConfig 数据转换代理
 @param progressBlock 进度回调
 @param responseBlock 响应回调，reformData为转化后的数据，如果reformerConfig返回的数据转换代理为nil，则reformData = response.dataObject；否则会根据数据转换代理方法“- reformData:”返回对应类型的对象，并且可通过reformData.isSuccess判断数据请求是成功还是失败。
 @return 请求任务编号
 @warning requestModel 不能为 nil
 */
- (NSNumber *_Nullable)request:(id <EFNRequestModelReformer> _Nonnull)requestModel
                      reformer:(id <EFNResponseDataReformer> _Nullable (^_Nullable)(void))reformerConfig
                      progress:(void (^_Nullable) (NSProgress * _Nullable progress))progressBlock
                      response:(void (^_Nullable) (id _Nullable reformData, EFNResponse * _Nonnull response))responseBlock;

/**
 发起请求，不带进度

 @param configRequestBlock 请求配置回调
 @param successBlock 请求成功回调
 @param failureBlock 请求失败回调
 @return 请求任务ID
 */
- (NSNumber *_Nullable)request:(NS_NOESCAPE EFNConfigRequestBlock _Nonnull)configRequestBlock
                       success:(EFNCallBlock _Nullable )successBlock
                       failure:(EFNCallBlock _Nullable )failureBlock;

/**
 发起请求，带进度

 @param configRequestBlock 请求配置回调
 @param progressBlock 进度回调
 @param successBlock 请求成功回调
 @param failureBlock 请求失败回调
 @return 请求任务ID
 */
- (NSNumber *_Nullable)request:(NS_NOESCAPE EFNConfigRequestBlock _Nonnull)configRequestBlock
                      progress:(EFNProgressBlock _Nullable)progressBlock
                       success:(EFNCallBlock _Nullable )successBlock
                       failure:(EFNCallBlock _Nullable )failureBlock;

@end

#pragma mark - Resume Class Category

/**
 继续请求
 */
@interface EFNetHelper (Resume)

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

@end

#pragma mark - Suspend Class Category
/**
 暂停请求
 */
@interface EFNetHelper (Suspend)

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

@end

#pragma mark - Cancel Class Category
/**
 取消请求
 */
@interface EFNetHelper (Cancel)

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

@interface EFNetHelper (Deprecated)

/**
 根据Request获取HTTPMethod
 
 @param request request
 @return HTTPMethod
 */
+ (NSString *_Nonnull)getHTTPMethodWithRequest:(EFNRequest *_Nonnull)request EFNDeprecated("请直接使用request.HTTPMethod");

/**
 根据Request获取ApiMethod
 
 @param request request
 @return ApiMethod
 */
+ (NSString *_Nullable)getApiMethodWithRequest:(EFNRequest *_Nonnull)request EFNDeprecated("未来版本可能会移除该方法");

@end

#pragma mark - 默认全局配置
@interface EFNDefaultConfig :NSObject <EFNGeneralConfigDelegate>

/**
 默认配置单例

 @return 单例对象
 */
+ (instancetype _Nonnull )shareConfig;

@end
