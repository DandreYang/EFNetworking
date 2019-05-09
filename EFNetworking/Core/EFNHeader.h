//
//  EFNHeader.h
//  EFNetworking
//
//  Created by Dandre on 2018/3/29.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#ifndef EFNHeader_h
#define EFNHeader_h

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

#define EFNDeprecated(instead) NS_DEPRECATED(2_0, 2_0, 2_0, 2_0, instead)

#if DEBUG
#define EFNLog(...) @autoreleasepool {\
NSString * _efnlog_pre_ = @"\n============ EFNetworking Debug Log ============\n\n";\
NSString * _efnlog_end_ = @"\n\n================================================\n";\
NSString * _efnlog_content_ = [[NSString alloc] initWithFormat:__VA_ARGS__];\
NSLog(@"%@%s [line:%d]:%@%@",_efnlog_pre_, __FUNCTION__, __LINE__, _efnlog_content_, _efnlog_end_);}
#else
#define EFNLog(...) {}
#endif

@class EFNRequest, EFNResponse, EFNUploadData;
@protocol EFNSignService, EFNGeneralConfigDelegate;

#pragma mark - Defined Block

/**
 全局配置Block

 @param config 全局配置代理
 */
typedef void (^EFNGeneralConfigBlock) (id <EFNGeneralConfigDelegate> _Nonnull config);

/**
 请求配置Block

 @param request 请求配置实例
 */
typedef void (^EFNConfigRequestBlock)(EFNRequest * _Nonnull request);

/**
 进度回调Block

 @param progress 进度
 */
typedef void (^EFNProgressBlock)(NSProgress * _Nonnull progress);

/**
 响应回调Block

 @param response 响应对象
 */
typedef void (^EFNCallBlock)(EFNResponse * _Nonnull response);

#pragma mark - Defined Enum

/// 网络状态
typedef NS_ENUM(NSInteger, EFNReachableStatus) {
    /// 未知
    EFNReachableStatusUnknown          = -1,
    /// 无网络
    EFNReachableStatusNotReachable     = 0,
    /// 蜂窝移动网络
    EFNReachableStatusReachableViaWWAN = 1,
    /// WiFi
    EFNReachableStatusReachableViaWiFi = 2,
};

/// 请求类型 常规/上传/下载
typedef NS_ENUM(NSInteger, EFNRequestType) {
    /// 常规请求，如 GET/POST/PUT/DELETE等
    EFNRequestTypeGeneral               = 0,
    /// FormData上传
    EFNRequestTypeFormDataUpload        = 1,
    /// 文件流上传
    EFNRequestTypeStreamUpload          = 2,
    /// 下载
    EFNRequestTypeDownload              = 3
};

/// HTTP请求方式
typedef NSString * EFNHTTPMethod NS_STRING_ENUM;
/// POST
static EFNHTTPMethod const _Nonnull EFNHTTPMethodPOST       = @"POST";
/// GET
static EFNHTTPMethod const _Nonnull EFNHTTPMethodGET        = @"GET";
/// HEAD
static EFNHTTPMethod const _Nonnull EFNHTTPMethodHEAD       = @"HEAD";
/// DELETE
static EFNHTTPMethod const _Nonnull EFNHTTPMethodDELETE     = @"DELETE";
/// PUT
static EFNHTTPMethod const _Nonnull EFNHTTPMethodPUT        = @"PUT";
/// PATCH
static EFNHTTPMethod const _Nonnull EFNHTTPMethodPATCH      = @"PATCH";

/// 请求体序列化类型
typedef NS_ENUM(NSInteger, EFNRequestSerializerType) {
    /// HTTP：默认类型
    EFNRequestSerializerTypeHTTP    = 1,
    /// JSON：默认会将请求头中的`Content-Type`设置为`application/json`,并且将请求体编码成JSON格式
    EFNRequestSerializerTypeJSON    = 2,
    /// Plist：默认会将请求头中的`Content-Type`设置为`application/x-plist`,并且将请求体编码成PropertyList格式
    EFNRequestSerializerTypePlist   = 3
};

/// 响应体序列化类型
typedef NS_ENUM(NSInteger, EFNResponseSerializerType) {
    /// HTTP：默认类型
    EFNResponseSerializerTypeHTTP           = 1,
    /// JSON：支持接收的 MIME 类型: `application/json` 、 `text/json` 或 `text/javascript`
    EFNResponseSerializerTypeJSON           = 2,
    /// XML：支持接收的 MIME 类型: `application/xml` 或 `text/xml`
    EFNResponseSerializerTypeXML            = 3,
    /// Plist：支持接收的 MIME 类型: `application/x-plist`
    EFNResponseSerializerTypePlist          = 4,
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
    /// XMLDocument(MacOS支持)：支持接收的 MIME 类型: `application/xml` 或 `text/xml`
    EFNResponseSerializerTypeXMLDocument    = 5
#endif
};

#pragma mark - Defined Protocol

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
@property (nonatomic, nonnull) EFNHTTPMethod HTTPMethod;
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
@property (nonatomic, strong) NSArray <__kindof EFNUploadData *>* _Nullable formDatas;
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
