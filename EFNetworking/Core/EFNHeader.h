//
//  EFNHeader.h
//  EFNetworking
//
//  Created by Dandre on 2018/3/29.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#ifndef EFNHeader_h
#define EFNHeader_h

#import "EFNRequest.h"
#import "EFNResponse.h"

#define EFN_SAFE_BLOCK(blockName, ...) ({ !blockName ? nil : blockName(__VA_ARGS__); })

#define dispatch_efn_sync_main_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_sync(dispatch_get_main_queue(), block);\
    }

#define dispatch_efn_async_main_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }

#if DEBUG
    #define EFNLog(format, ...) NSLog(format, ##__VA_ARGS__)
#else
    #define EFNLog(format, ...) {}
#endif

/**
 请求配置Block

 @param request 请求配置实例
 */
typedef void (^EFNConfigRequestBlock)(EFNRequest * _Nonnull request);

/**
 进度回调Block

 @param progress 进度
 */
typedef void (^EFNProgressBlock)(NSProgress * _Nullable progress);

/**
 响应回调Block

 @param response 响应对象
 */
typedef void (^EFNCallBlock)(EFNResponse * _Nullable response);


/**
 网络状态

 - EFNReachableStatusUnknown: 未知
 - EFNReachableStatusNotReachable: 无网络
 - EFNReachableStatusReachableViaWWAN: 蜂窝网络
 - EFNReachableStatusReachableViaWiFi: WiFi
 */
typedef NS_ENUM(NSInteger, EFNReachableStatus) {
    EFNReachableStatusUnknown          = -1,
    EFNReachableStatusNotReachable     = 0,
    EFNReachableStatusReachableViaWWAN = 1,
    EFNReachableStatusReachableViaWiFi = 2,
};

#pragma mark - 协议方法

/**
 网络请求管理配置类
 */
@protocol EFNGeneralConfigDelegate <NSObject>

@required
/**
 全局服务器配置
 */
@property (nonatomic, copy, nullable) NSString *generalServer;
/**
 全局通用参数配置
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *generalParameters;
/**
 全局通用HEADER配置
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *generalHeaders;
/**
 全局通用下载保存路径, 只能是文件夹，否则会覆盖文件
 */
@property (nonatomic, copy, nullable) NSString *generalDownloadSavePath;
/**
 全局配置 RequestSerializerType
 */
@property (nonatomic, assign) EFNRequestSerializerType generalRequestSerializerType;
/**
 全局配置 ResponseSerializerType
 */
@property (nonatomic, assign) EFNResponseSerializerType generalResponseSerializerType;

/**
 签名服务代理 可以设置签名、认证等信息
 */
@property (nonatomic, strong, nullable) id <EFNSignService> signService;

@end

#pragma mark 签名

/**
 签名服务
 */
@protocol EFNSignService <NSObject>
@required
- (NSDictionary<NSString *, NSString *> *_Nonnull)signForRequest:(EFNRequest *_Nonnull)request;
@end

#pragma mark 数据转换

/**
 * 请求数据模型转换协议
 * 此协议用于将数据模型转换成接口请求对象
 */
@protocol EFNRequestModelReformer <NSObject>

@required
/**
 请求接口
 */
@property (nonatomic, copy) NSString * _Nonnull api;
/**
 请求方法 读取枚举值
 */
@property (nonatomic, assign) EFNHTTPMethod HTTPMethod;
/**
 请求类型 默认常规
 */
@property (nonatomic, assign) EFNRequestType requestType;
/**
 将对象转换成dictionary的方法
 */
- (NSDictionary *_Nonnull)toDictionary;

@optional
/**
 数据服务器地址，为nil自动时取全局通用配置
 */
@property (nonatomic, copy) NSString * _Nullable server;
/**
 上传的formdata数据
 */
@property (nonatomic, strong) NSArray <EFNUploadFormData *>* _Nullable formDatas;
/**
 签名服务，为nil时自动取全局通用配置
 */
@property (nonatomic, weak) id <EFNSignService> _Nullable signService;

@end

/**
 * 响应数据转换协议
 * 此协议用于将请求回来的数据（一般是JSON格式）进行处理，转换成指定数据格式（一般是数据模型）
 */
@protocol EFNResponseDataReformer <NSObject>

@required
@property (nonatomic, assign) BOOL isSuccess;

/**
 数据转换

 @param rawData 原始数据（一般是dictionary/array）
 @return 转换后的数据（一般是数据模型，可根据业务层需要自定义处理）
 */
- (id _Nullable)reformData:(id<NSObject, NSCopying>_Nullable)rawData;

@end

#endif /* EFNHeader_h */
