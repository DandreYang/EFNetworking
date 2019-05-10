//
//  EFNRequest.h
//  EFNetworking
//
//  Created by Dandre on 2018/3/28.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EFNHeader.h"

@protocol EFNSignService;


@class EFNUploadData;

/**
 请求的基类
 */
@interface EFNRequest : NSObject

/**
 签名服务代理 可以设置签名、认证等信息，如果不设置，会自动取全局配置
 - 如果单个接口的签名与统一配置的签名不同，例如使用的一些第三方平台的API，这种情况也可以自定义对应的签名代理，然后赋值给对应EFNRequest对象的signService属性
 */
@property (nonatomic, weak, nullable) id <EFNSignService> signService;

/**
 当前请求的RequestID
 */
@property (nonatomic, strong, readonly, nullable) NSNumber * requestID;

/**
 当前请求的服务器地址 如：http://www.abc.com/api/, 默认为nil,如果为nil时会自动取全局配置中的generalServer属性
 */
@property (nonatomic, copy, nullable) NSString *server;

/**
 当前请求的接口方法 如：getUserInfo，默认为 nil
 */
@property (nonatomic, copy, nullable) NSString *api;

/**
 当前请求的URL 如：http://www.abc.com/api/getUserInfo?userid=1000，默认为 nil, 如果设置了 url，server和api属性将失效
 */
@property (nonatomic, copy, nullable) NSString *url;

/**
 请求体的参数
 */
@property (nonatomic, strong, nullable) id <NSObject> parameters;

/**
 请求头的参数
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *headers;

/**
 是否启用全局服务器地址配置，默认为 YES，启用后 当server属性为nil时，会自动取全局配置中的generalServer
 */
@property (nonatomic, assign) BOOL enableGeneralServer;

/**
 是否启用全局配置中的请求头generalHeaders配置，默认为YES，启用后会自动添加generalHeaders到headers中
 */
@property (nonatomic, assign) BOOL enableGeneralHeaders;

/**
 是否启用全局请求参数，默认为YES，启用后会自动添加generalParameters到parameters中
 */
@property (nonatomic, assign) BOOL enableGeneralParameters;

/**
 请求类型
 */
@property (nonatomic, assign) EFNRequestType requestType;

/**
 请求方法
 */
@property (nonatomic, nonnull) EFNHTTPMethod HTTPMethod;

/**
 配置 RequestSerializerType, 默认为 EFNRequestSerializerTypeHTTP（参考<EFNDefaultConfig>的默认值）
 */
@property (nonatomic, assign) EFNRequestSerializerType requestSerializerType;

/**
 配置 ResponseSerializerType，默认为 EFNResponseSerializerTypeHTTP（参考<EFNDefaultConfig>的默认值）
 */
@property (nonatomic, assign) EFNResponseSerializerType responseSerializerType;

/**
 请求超时的时间，默认取generalTimeoutInterval
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 上传的FormData数据，只用于requestType = EFNRequestTypeFormDataUpload 时
 */
@property (nonatomic, strong, nullable) NSArray<__kindof EFNUploadData *> *uploadFormDatas;

/**
 文件保存路径，可以是文件夹或文件名，默认取generalDownloadSavePath  只用于requestType = EFNRequestTypeFormDataDownload 时
 */
@property (nonatomic, copy, nullable) NSString *downloadSavePath;

/**
 是否支持断点下载 默认 YES
 */
@property (nonatomic, assign) BOOL enableResumeDownload;

/**
 是否允许缓存
 */
@property (nonatomic, assign) BOOL  enableCache;

/**
 缓存过期时间，单位/秒，只有当enableCache属性为YES时才有效, 默认 1800秒
 */
@property (nonatomic, assign) NSTimeInterval cacheTimeout;

@end

@interface EFNRequest (AppendUploadData)

#pragma mark - Append Upload Part Methods
/// 适用于 EFNRequestTypeStreamUpload 上传方式
- (BOOL)appendUploadDataWithFileData:(NSData *_Nonnull)fileData;
/// 适用于 EFNRequestTypeFormDataUpload 上传方式
- (BOOL)appendUploadDataWithFileData:(NSData *_Nonnull)fileData name:(NSString *_Nonnull)name;
/// 适用于 EFNRequestTypeFormDataUpload 上传方式
- (BOOL)appendUploadDataWithFileData:(NSData *_Nonnull)fileData name:(NSString *_Nonnull)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType;

/// 适用于 EFNRequestTypeStreamUpload 上传方式
- (BOOL)appendUploadDataWithFileURL:(NSURL *_Nonnull)fileURL;
/// 适用于 EFNRequestTypeFormDataUpload 上传方式
- (BOOL)appendUploadDataWithFileURL:(NSURL *_Nonnull)fileURL name:(NSString *_Nonnull)name;
/// 适用于 EFNRequestTypeFormDataUpload 上传方式
- (BOOL)appendUploadDataWithFileURL:(NSURL *_Nonnull)fileURL name:(NSString *_Nonnull)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType;

@end

@interface EFNRequest (Deprecated)

#pragma mark - Deprecated Methods
- (void)addFormDataWithName:(NSString *_Nullable)name fileData:(NSData *_Nonnull)fileData
EFNDeprecated("请替换为`-appendUploadDataWithFileData:name:`");
- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName fileData:(NSData *_Nonnull)fileData
EFNDeprecated("请替换为`-appendUploadDataWithFileData:name:fileName:mimeType`");
- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType fileData:(NSData *_Nonnull)fileData
EFNDeprecated("请替换为`-appendUploadDataWithFileData:name:fileName:mimeType`");
- (void)addFormDataWithName:(NSString *_Nullable)name fileURL:(NSURL *_Nonnull)fileURL
EFNDeprecated("请替换为`-appendUploadDataWithFileURL:name:`");
- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName fileURL:(NSURL *_Nonnull)fileURL
EFNDeprecated("请替换为`-appendUploadDataWithFileURL:name:fileName:mimeType`");
- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType fileURL:(NSURL *_Nonnull)fileURL
EFNDeprecated("请替换为`-appendUploadDataWithFileURL:name:fileName:mimeType`");

@end


/**
 文件上传UploadData类，适用于非FormData上传的方式
 */
@interface EFNUploadData : NSObject

/// 需要上传的FormData数据
@property (nonatomic, strong, readonly, nullable) NSData *fileData;

/// 需要上传的文件地址
@property (nonatomic, strong, readonly, nullable) NSURL *fileURL;

- (instancetype _Nonnull )init NS_UNAVAILABLE;
- (instancetype _Nonnull )new NS_UNAVAILABLE;

/**
 实例化方法

 @param fileURL 文件URL
 @return 实例对象
 */
- (instancetype _Nonnull )initWithFileURL:(NSURL *_Nonnull)fileURL NS_DESIGNATED_INITIALIZER;

/**
 实例化方法

 @param fileData 文件数据
 @return 实例对象
 */
- (instancetype _Nonnull )initWithFileData:(NSData *_Nonnull)fileData NS_DESIGNATED_INITIALIZER;

@end

/**
 文件上传FormData类，适用于使用FormData上传的场景
 
 1.0.1版本之前是 EFNUploadFormData, 1.0.1之后的版本重写的此类
 */
@interface EFNMutipartFormData : EFNUploadData

/// 与formData数据关联的名称（key），一般不能为空。例如：image
@property (nonatomic, copy, readonly, nullable) NSString *name;

/// 提交给服务器端的文件名，用于服务器端保存文件
@property (nonatomic, copy, readonly, nullable) NSString *fileName;

/// 文件的MIME类型，（例如，一个JPEG图片的MIME类型为image/jpeg）
@property (nonatomic, copy, readonly, nullable) NSString *mimeType;


/**
 根据文件二进制数据和文件的键名实例化的方法

 @param fileData 文件的二进制数据
 @param name 与formData数据关联的名称（key）
 @return 实例化对象
 */
+ (instancetype _Nonnull)formDataWithFileData:(NSData *_Nonnull)fileData name:(NSString *_Nonnull)name;

/**
 根据文件二进制数据和文件的键名实例化的方法
 
 @param fileData 文件的二进制数据
 @param name 与formData数据关联的名称（key）
 @param fileName 服务端保存的文件名称
 @return 实例化对象
 */
+ (instancetype _Nonnull)formDataWithFileData:(NSData *_Nonnull)fileData name:(NSString *_Nonnull)name fileName:(NSString *_Nullable)fileName;

/**
 根据文件二进制数据和文件的键名实例化的方法
 
 @param fileData 文件的二进制数据
 @param name 与formData数据关联的名称（key）
 @param fileName 服务端保存的文件名称
 @param mimeType 文件的MIME类型
 @return 实例化对象
 */
+ (instancetype _Nonnull)formDataWithFileData:(NSData *_Nonnull)fileData name:(NSString *_Nonnull)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType;

/**
 根据文件二进制数据和文件的键名实例化的方法
 
 @param fileURL 文件的URL
 @param name 与formData数据关联的名称（key）
 @return 实例化对象
 */
+ (instancetype _Nonnull)formDataWithFileURL:(NSURL *_Nonnull)fileURL name:(NSString *_Nonnull)name ;

/**
 根据文件二进制数据和文件的键名实例化的方法
 
 @param fileURL 文件的URL
 @param name 与formData数据关联的名称（key）
 @param fileName 服务端保存的文件名称
 @return 实例化对象
 */
+ (instancetype _Nonnull)formDataWithFileURL:(NSURL *_Nonnull)fileURL name:(NSString *_Nonnull)name fileName:(NSString *_Nullable)fileName;

/**
 根据文件二进制数据和文件的键名实例化的方法
 
 @param fileURL 文件的URL
 @param name 与formData数据关联的名称（key）
 @param fileName 服务端保存的文件名称
 @param mimeType 文件的MIME类型
 @return 实例化对象
 */
+ (instancetype _Nonnull)formDataWithFileURL:(NSURL *_Nonnull)fileURL name:(NSString *_Nonnull)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType;

- (instancetype _Nonnull )initWithFileURL:(NSURL *_Nonnull)fileURL NS_UNAVAILABLE;
- (instancetype _Nonnull )initWithFileData:(NSData *_Nonnull)fileData NS_UNAVAILABLE;

@end

/**
 文件上传 StreamUploadData 类，适用于不是FormData上传的场景
 */
@interface EFNStreamUploadData : EFNUploadData
@end
