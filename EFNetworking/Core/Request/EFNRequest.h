//
//  EFNRequest.h
//  EFNetworking
//
//  Created by Dandre on 2018/3/28.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EFNSignService;
/**
 请求类型 常规/上传/下载
 */
typedef NS_ENUM(NSInteger, EFNRequestType) {
    EFNRequestTypeGeneral               = 0,    // 常规请求，如 GET/POST/PUT/DELETE等
    EFNRequestTypeFormDataUpload        = 1,    // FormData上传
    EFNRequestTypeStreamUpload          = 2,    // 文件流上传
    EFNRequestTypeDownload              = 3,     // 下载
    EFNRequestTypeDefault               = EFNRequestTypeGeneral
};

/**
 HTTP请求方式
 */
typedef NS_ENUM(NSInteger, EFNHTTPMethod) {
    EFNHTTPMethodPOST   = 0,    // POST
    EFNHTTPMethodGET    = 1,    // GET
    EFNHTTPMethodHEAD   = 2,    // HEAD
    EFNHTTPMethodDELETE = 3,    // DELETE
    EFNHTTPMethodPUT    = 4,    // PUT
    EFNHTTPMethodPATCH  = 5,    // PATCH
};

/**
 请求体序列化类型
 
 - EFNRequestSerializerTypeHTTP: HTTP：默认类型
 - EFNRequestSerializerTypeJSON: JSON：默认会将请求头中的`Content-Type`设置为`application/json`,并且将请求体编码成JSON格式
 - EFNRequestSerializerTypePlist: Plist：默认会将请求头中的`Content-Type`设置为`application/x-plist`,并且将请求体编码成PropertyList格式
 */
typedef NS_ENUM(NSInteger, EFNRequestSerializerType) {
    EFNRequestSerializerTypeHTTP    = 1,
    EFNRequestSerializerTypeJSON    = 2,
    EFNRequestSerializerTypePlist   = 3
};

/**
 响应体序列化类型
 
 - EFNResponseSerializerTypeHTTP: HTTP：默认类型
 - EFNResponseSerializerTypeJSON: JSON：支持接收的 MIME 类型: `application/json` 、 `text/json` 或 `text/javascript`
 - EFNResponseSerializerTypeXML: XML：支持接收的 MIME 类型: `application/xml` 或 `text/xml`
 - EFNResponseSerializerTypePlist: Plist：支持接收的 MIME 类型: `application/x-plist`
 - EFNResponseSerializerTypeXMLDocument: XMLDocument(MacOS支持)：支持接收的 MIME 类型: `application/xml` 或 `text/xml`
 */
typedef NS_ENUM(NSInteger, EFNResponseSerializerType) {
    EFNResponseSerializerTypeHTTP           = 1,
    EFNResponseSerializerTypeJSON           = 2,
    EFNResponseSerializerTypeXML            = 3,
    EFNResponseSerializerTypePlist          = 4,
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
    EFNResponseSerializerTypeXMLDocument    = 5
#endif
};

@class EFNUploadFormData;

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
@property (nonatomic, assign) EFNHTTPMethod HTTPMethod;

/**
 配置 RequestSerializerType, 默认为 EFNRequestSerializerTypeHTTP（参考EFNDefaultConfig的默认值）
 */
@property (nonatomic, assign) EFNRequestSerializerType requestSerializerType;

/**
 配置 ResponseSerializerType，默认为 EFNResponseSerializerTypeJSON（参考EFNDefaultConfig的默认值）
 */
@property (nonatomic, assign) EFNResponseSerializerType responseSerializerType;

/**
 请求超时的时间，默认取generalTimeoutInterval
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 上传的FormData数据，只用于requestType = EFNRequestTypeFormDataUpload 时
 */
@property (nonatomic, strong, nullable) NSArray<EFNUploadFormData *> *uploadFormDatas;

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

#pragma mark - Add FormData Methods
- (void)addFormDataWithName:(NSString *_Nullable)name fileData:(NSData *_Nonnull)fileData;
- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName fileData:(NSData *_Nonnull)fileData;
- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType fileData:(NSData *_Nonnull)fileData;

- (void)addFormDataWithName:(NSString *_Nullable)name fileURL:(NSURL *_Nonnull)fileURL;
- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName fileURL:(NSURL *_Nonnull)fileURL;
- (void)addFormDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType fileURL:(NSURL *_Nonnull)fileURL;

@end

/**
 文件上传FormData类
 */
@interface EFNUploadFormData : NSObject

@property (nonatomic, copy, nullable) NSString *name;           /**< 与formData数据关联的名称（key），一般不能为空。例如：image */
@property (nonatomic, copy, nullable) NSString *fileName;       /**< 提交给服务器端的文件名，用于服务器端保存文件 */
@property (nonatomic, copy, nullable) NSString *mimeType;       /**< 文件的MIME类型，（例如，一个JPEG图片的MIME类型为image/jpeg）*/
@property (nonatomic, strong, nullable) NSData *fileData;       /**< 需要上传的FormData数据 */
@property (nonatomic, strong, nullable) NSURL *fileURL;         /**< 需要上传的文件地址 */

#pragma mark - Methods
+ (instancetype _Nonnull)formDataWithName:(NSString *_Nullable)name fileData:(NSData *_Nonnull)fileData;
+ (instancetype _Nonnull)formDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName fileData:(NSData *_Nonnull)fileData;
+ (instancetype _Nonnull)formDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType fileData:(NSData *_Nonnull)fileData;

+ (instancetype _Nonnull)formDataWithName:(NSString *_Nullable)name fileURL:(NSURL *_Nonnull)fileURL;
+ (instancetype _Nonnull)formDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName fileURL:(NSURL *_Nonnull)fileURL;
+ (instancetype _Nonnull)formDataWithName:(NSString *_Nullable)name fileName:(NSString *_Nullable)fileName mimeType:(NSString *_Nullable)mimeType fileURL:(NSURL *_Nonnull)fileURL;

@end
