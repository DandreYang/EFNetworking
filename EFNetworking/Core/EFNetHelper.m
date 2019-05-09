//
//  EFNetHelper.m
//  EFNetworking
//
//  Created by Dandre on 2018/3/23.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import "EFNetHelper.h"
#import <objc/runtime.h>
#import "NSDictionary+EFNetworking.h"

#define Lock() [self.lock lock]
#define Unlock() [self.lock unlock]
static NSString * const EFNetHelperLockName = @"vip.dandre.efnetworking.nethelper.lock";

NSString * EFNetworkingDefaultDownloadDirectory(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"EFNetworking/Download"];
    return path;
}

@interface EFNetHelper ()

/** 请求池 存放所有请求的任务ID */
@property (nonatomic, strong) NSMutableArray <NSNumber *> * requestPool;
/** 网关 用于处理网络请求 */
@property (nonatomic, strong, readwrite) EFNetProxy * netProxy;
/** 网络缓存管理器 */
@property (nonatomic, strong, readwrite) EFNCacheHelper * cacheHelper;
/** 是否正在请求数据 */
@property (nonatomic, assign, readwrite) BOOL isLoading;

@property (nonatomic, strong, readwrite) NSLock *lock;

@end

@implementation EFNetHelper

#pragma mark - Life Cycle
+ (instancetype)shareHelper
{
    static EFNetHelper *helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [self helper];
    });
    
    return helper;
}

+ (instancetype)helper
{
    return [[[self class] alloc] init];
}

- (id<EFNGeneralConfigDelegate>)config
{
    if (!_config) {
        _config = [EFNDefaultConfig shareConfig];
    }
    
    return _config;
}

- (void)dealloc
{
    if (self.isLoading) {
        [self cancelAllRequests];
    }
    self.requestPool = nil;
    self.cacheHelper = nil;
    self.netProxy = nil;
}

- (NSMutableArray<NSNumber *> *)requestPool
{
    if (!_requestPool) {
        _requestPool = @[].mutableCopy;
    }
    
    return _requestPool;
}

- (EFNetProxy *)netProxy
{
    if (!_netProxy) {
        // 这里没有使用EFNetProxy单例，是为了更好的适应各种不同的网络请求。
        // 通过EFNetHelper.shareHelper实例化的网络管理对象本身就是单例，其内部管理的是同一个网关。
        _netProxy = EFNetProxy.newProxy;
    }
    
    return _netProxy;
}

- (EFNCacheHelper *)cacheHelper
{
    if (!_cacheHelper) {
        _cacheHelper = [EFNCacheHelper shared];
    }
    
    return _cacheHelper;
}

- (NSLock *)lock {
    if (!_lock) {
        _lock = [[NSLock alloc] init];
        _lock.name = EFNetHelperLockName;
    }
    
    return _lock;
}

/**
 全局通用配置
 
 @param configHandler 配置回调
 */
+ (void)generalConfigHandler:(NS_NOESCAPE void (^_Nonnull) (id <EFNGeneralConfigDelegate> _Nonnull config))configHandler
{
    configHandler([EFNDefaultConfig shareConfig]);
    
    EFNLog(@"\n\n\
           /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\n\
           /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\n\
           ///////////                         /////////                         /////////         ///////////////       ///////////\n\
           ///////////       ///////////////////////////       ///////////////////////////              //////////       ///////////\n\
           ///////////       ///////////////////////////       ///////////////////////////       ///       ///////       ///////////\n\
           ///////////                         /////////                         /////////       //////       ////       ///////////\n\
           ///////////       ///////////////////////////       ///////////////////////////       /////////       /       ///////////\n\
           ///////////       ///////////////////////////       ///////////////////////////       /////////////           ///////////\n\
           ///////////                         /////////       ///////////////////////////       ///////////////         ///////////\n\
           /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\n\
           /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\n\n%@", [EFNDefaultConfig shareConfig]);
}

- (NSNumber *)request:(id <EFNRequestModelReformer> )requestModel
             reformer:(id <EFNResponseDataReformer> (^)(void))reformerConfig
             progress:(void (^) (NSProgress * _Nullable progress))progressBlock
             response:(void (^) (id reformData, EFNResponse *response))responseBlock
{
    // 统一回调处理
    void (^completeHanlder)(EFNResponse * _Nonnull response, BOOL isSuccess) = ^(EFNResponse * _Nonnull response, BOOL isSuccess) {
        Lock();
        if ([self.requestPool containsObject:response.requestID]) {
            [self.requestPool removeObject:response.requestID];
        }
        Unlock();
        id reformerData = nil;
        if (reformerConfig) {
            id<EFNResponseDataReformer> reformer = reformerConfig();
            
            if (reformer == nil) {
                reformerData = [(NSDictionary *)response.dataObject copy];
            }else{
                reformer = [reformer reformData:(NSDictionary *)response.dataObject];
                reformer.isSuccess = isSuccess;
                
                reformerData = reformer;
            }
        }else{
            reformerData = [(NSDictionary *)response.dataObject copy];
        }
        EFN_SAFE_BLOCK(responseBlock,reformerData, response);
    };
    
    // 请求服务
    NSNumber *requestID = [self request:^(EFNRequest * _Nonnull request) {

        request.server = requestModel.server;
        request.api = requestModel.api;
        request.HTTPMethod = requestModel.HTTPMethod;
        request.requestType = requestModel.requestType;
        
         // 根据RequestModel设置签名
        if (requestModel.signService && [requestModel.signService respondsToSelector:@selector(signForRequest:)]) {
            request.signService = requestModel.signService;
        }
        
        if (requestModel.requestType == EFNRequestTypeFormDataUpload && requestModel.formDatas) {
            request.uploadFormDatas = requestModel.formDatas.copy;
        }
        
        NSMutableDictionary *dict = [requestModel toDictionary].mutableCopy;
        [dict efn_removeObjectsForProtocol:@protocol(EFNRequestModelReformer)];
        
        request.parameters = dict.copy;
    }
                                         progress:progressBlock
                                          success:^(EFNResponse * _Nonnull response) {
                                              completeHanlder(response, YES);
                                          }
                                          failure:^(EFNResponse * _Nonnull response) {
                                              completeHanlder(response, NO);
                                          }];
    
    return requestID;
}

- (NSNumber *_Nullable)request:(NS_NOESCAPE EFNConfigRequestBlock _Nonnull)configRequestBlock
                       success:(EFNCallBlock _Nullable )successBlock
                       failure:(EFNCallBlock _Nullable )failureBlock
{
    return [self request:configRequestBlock
                progress:nil
                 success:successBlock
                 failure:failureBlock];
}

- (NSNumber *_Nullable)request:(NS_NOESCAPE EFNConfigRequestBlock _Nonnull)configRequestBlock
                      progress:(EFNProgressBlock _Nullable)progressBlock
                       success:(EFNCallBlock _Nullable )successBlock
                       failure:(EFNCallBlock _Nullable )failureBlock
{
    __block EFNRequest *efnRequest = nil;
    NSNumber *requestID = [self request:^(EFNRequest * _Nonnull request) {
                            EFN_SAFE_BLOCK(configRequestBlock, request);
                            efnRequest = request;
                        }
                          uploadProgress:^(NSProgress * _Nonnull progress) {
                              dispatch_efn_async_main_safe(^{
                                  if (efnRequest.requestType == EFNRequestTypeStreamUpload ||
                                      efnRequest.requestType == EFNRequestTypeFormDataUpload ) {
                                      EFN_SAFE_BLOCK(progressBlock, progress);
                                  }
                              });
                          }
                        downloadProgress:^(NSProgress * _Nonnull progress) {
                            dispatch_efn_async_main_safe(^{
                                EFN_SAFE_BLOCK(progressBlock, progress);
                            });
                        }
                                success:^(EFNResponse * _Nonnull response) {
                                    dispatch_efn_async_main_safe(^{
                                        EFN_SAFE_BLOCK(successBlock, response);
                                    });
                                } failure:^(EFNResponse * _Nonnull response) {
                                    dispatch_efn_async_main_safe(^{
                                        EFN_SAFE_BLOCK(failureBlock, response);
                                    });
                                }];
    
    return requestID;
}

#pragma mark - Private Methods
- (NSNumber *)request:(NS_NOESCAPE EFNConfigRequestBlock)configRequestBlock
       uploadProgress:(EFNProgressBlock _Nullable)uploadProgressBlock
     downloadProgress:(EFNProgressBlock _Nullable)downloadProgressBlock
              success:(EFNCallBlock _Nullable )successBlock
              failure:(EFNCallBlock _Nullable )failureBlock
{
    EFNRequest *request = [[EFNRequest alloc] init];
    EFN_SAFE_BLOCK(configRequestBlock, request);
    
    [self appendGeneraConfigForRequest:request];
    [self appendSignServiceForRequest:request];
    
    EFNLog(@"requestConfig:%@", request);
    
    if (request.enableCache && [self.cacheHelper containsObjectForRequest:request]) {
        EFNResponse *response = [self.cacheHelper responseForRequest:request];
        EFN_SAFE_BLOCK(successBlock, response);

        return nil;
    }
    
    // 统一回调处理
    void (^completeHandler)(EFNResponse * _Nonnull response, BOOL isSuccess) = ^(EFNResponse *_Nonnull response, BOOL isSuccess) {
        Lock();
        if ([self.requestPool containsObject:response.requestID]) {
            [self.requestPool removeObject:response.requestID];
        }
        Unlock();
        
        if (isSuccess) {
            // 缓存数据,并且只缓存无错误的数据
            if (request.enableCache && response.isCache == NO && response.error == nil) {
                [self.cacheHelper saveResponse:response forRequest:request];
            }
            
            EFN_SAFE_BLOCK(successBlock, response);
        } else {
            
            EFN_SAFE_BLOCK(failureBlock, response);
        }
    };
    
    NSNumber *requestID = [self.netProxy request:request
                                  uploadProgress:uploadProgressBlock
                                downloadProgress:downloadProgressBlock
                                         success:^(EFNResponse * _Nonnull response) {
                                             completeHandler(response, YES);
                                         } failure:^(EFNResponse * _Nonnull response) {
                                             completeHandler(response, NO);
                                         }];
    if (requestID) {
        Lock();
        [self.requestPool addObject:requestID];
        Unlock();
    }
    
    return requestID;
}

- (void)appendGeneraConfigForRequest:(EFNRequest *)request
{
    NSParameterAssert(request);
    if (!request.downloadSavePath || request.downloadSavePath.length == 0) {
        if (self.config && self.config.generalDownloadSavePath.length) {
            request.downloadSavePath = self.config.generalDownloadSavePath;
        }else{
            request.downloadSavePath = EFNetworkingDefaultDownloadDirectory();
        }
    }
    
    if (request.url.length == 0) {
        
        if (request.server.length == 0 && request.enableGeneralServer && self.config.generalServer.length > 0) {
            request.server = self.config.generalServer;
        }
        
        NSParameterAssert(request.server);
        if (request.api.length > 0) {
            NSMutableString *baseUrlString = request.server.mutableCopy;
            
            if (![baseUrlString hasSuffix:@"/"] && ![request.api hasPrefix:@"/"]) {
                [baseUrlString appendString:@"/"];
            }else if ([baseUrlString hasSuffix:@"/"] && [request.api hasPrefix:@"/"]){
                [baseUrlString deleteCharactersInRange:NSMakeRange(baseUrlString.length - 1, 1)];
            }
            [baseUrlString appendString:request.api];
            request.url = baseUrlString.copy;
        } else {
            request.url = request.server;
        }
    }
    
    NSParameterAssert(request.url);
    
    if (!request.signService || ![request.signService respondsToSelector:@selector(signForRequest:)]) {
        request.signService = self.config.signService;
    }
    
    if (request.enableGeneralHeaders && self.config.generalHeaders.count > 0) {
        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        [headers addEntriesFromDictionary:self.config.generalHeaders];
        
        if (request.headers) {
            [headers addEntriesFromDictionary:request.headers];
        }
        
        request.headers = headers;
    }
    
    if (!request.requestSerializerType) {
        request.requestSerializerType = self.config.generalRequestSerializerType;
    }
    
    if (!request.responseSerializerType) {
        request.responseSerializerType = self.config.generalResponseSerializerType;
    }
    
    if (request.enableGeneralParameters && self.config.generalParameters.count > 0) {
        
        if ([request.parameters isKindOfClass:NSDictionary.class]){
            NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
            [parameters addEntriesFromDictionary:self.config.generalParameters];
            
            if (((NSDictionary *)request.parameters).count > 0) {
                [parameters addEntriesFromDictionary:(NSDictionary *)request.parameters];
            }
    
            request.parameters = parameters.copy;
        }else {
            // 如果请求参数不是字典，公共参数不能直接加在请求参数中，需要做如下处理，将公共参数加在URL后面
            // 此处将公共参数加到请求的URL后面
            NSMutableString *urlStr = request.url.mutableCopy;
            NSString *urlQuery = self.config.generalParameters.efn_toURLQuery;
            
            // 如果url包含“?”，说明已经带了参数，此时需要将后面加入的参数进行处理才能追加在后面
            if ([urlStr containsString:@"?"]) {
                urlQuery = [urlQuery stringByReplacingOccurrencesOfString:@"?" withString:@"&"];
            }
            
            // 将公共参数追加在URL后面
            [urlStr appendString:urlQuery];
            
            request.url = urlStr;
        }
    }
}

- (void)appendSignServiceForRequest:(EFNRequest *)request
{
    if (!request.signService) {
        return;
    }
    
    NSDictionary *dict = [request.signService signForRequest:request];
    if (dict && dict.count) {
        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        [headers addEntriesFromDictionary:dict];
        
        if (request.headers) {
            [headers addEntriesFromDictionary:request.headers];
        }
        
        request.headers = headers;
    }
}

- (BOOL)isLoading
{
    if (self.requestPool.count == 0) {
        _isLoading = NO;
    }
    
    return _isLoading;
}

@end

#pragma mark - Resume Class Category

@implementation EFNetHelper (Resume)

- (void)resumeAllRequests
{
    [self.netProxy resumeWithRequestIDList:self.requestPool];
}

- (void)resumeWithRequestID:(NSNumber *_Nonnull)requestID
{
    [self.netProxy resumeWithRequestID:requestID];
}

- (void)resumeWithRequestIDList:(NSArray <NSNumber *> *_Nonnull)requestIDList
{
    [self.netProxy resumeWithRequestIDList:requestIDList];
}

@end

#pragma mark - Suspend Class Category

@implementation EFNetHelper (Suspend)

- (void)suspendAllRequests
{
    [self.netProxy suspendWithRequestIDList:self.requestPool];
}

- (void)suspendWithRequestID:(NSNumber *_Nonnull)requestID
{
    [self.netProxy suspendWithRequestID:requestID];
}

- (void)suspendWithRequestIDList:(NSArray <NSNumber *> *_Nonnull)requestIDList
{
    [self.netProxy suspendWithRequestIDList:requestIDList];
}

@end

#pragma mark - Cancel Class Category

@implementation EFNetHelper (Cancel)

- (void)cancelAllRequests
{
    [self.netProxy cancelWithRequestIDList:self.requestPool];
    Lock();
    [self.requestPool removeAllObjects];
    Unlock();
}

- (void)cancelWithRequestID:(NSNumber *_Nonnull)requestID
{
    Lock();
    NSAssert([self.requestPool containsObject:requestID], @"当前要取消的请求任务不在该网络管理类的请求池中");
    [self.netProxy cancelWithRequestID:requestID];
    [self.requestPool removeObject:requestID];
    Unlock();
}

- (void)cancelWithRequestIDList:(NSArray<NSNumber *> *_Nonnull)requestIDList
{
    [self.netProxy cancelWithRequestIDList:requestIDList];
    Lock();
    [self.requestPool removeObjectsInArray:requestIDList];
    Unlock();
}

@end

@implementation EFNetHelper (Deprecated)

+ (NSString *)getHTTPMethodWithRequest:(EFNRequest *_Nonnull)request
{
    return request.HTTPMethod;
}

+ (NSString *)getApiMethodWithRequest:(EFNRequest *_Nonnull)request
{
    if (!request) {
        return @"";
    }
    
    if (request.url) return [NSURL URLWithString:request.url].path;
    
    NSString *url = request.server.copy;
    if (!url) {
        url = [EFNDefaultConfig shareConfig].generalServer;
    }
    
    if (!url) return @"";

    if (request.api.length) {
        [url stringByAppendingPathComponent:request.api];
    }
    return [NSURL URLWithString:url].path;
}

@end

@interface EFNDefaultConfig ()

@end

@implementation EFNDefaultConfig

@synthesize generalDownloadSavePath;

@synthesize generalHeaders;

@synthesize generalParameters;

@synthesize generalRequestSerializerType;

@synthesize generalResponseSerializerType;

@synthesize generalServer;

@synthesize signService;

static EFNDefaultConfig *config = nil;
+ (instancetype)shareConfig
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[EFNDefaultConfig alloc] init];
    });
    
    return config;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.generalRequestSerializerType = EFNRequestSerializerTypeHTTP;
        self.generalResponseSerializerType = EFNResponseSerializerTypeJSON;
    }
    return self;
}

- (NSString *)description
{
    NSString *des = [NSString stringWithFormat:@"EFNetworking General Config <%p>: \n signService: %@\n generalServer: %@\n generalParameters: %@\n generalHeaders: %@\n generalDownloadSavePath: %@\n generalRequestSerializerType: %@\n generalResponseSerializerType: %@",
                     self,
                     self.signService,
                     self.generalServer,
                     self.generalParameters,
                     self.generalHeaders,
                     self.generalDownloadSavePath,
                     [self getRequestSerializerType:self.generalRequestSerializerType],
                     [self getResponseSerializerType:self.generalResponseSerializerType]];
    
   return des;
}

#pragma mark - Private Methods
- (NSString *)getRequestSerializerType:(EFNRequestSerializerType)type {
    switch (type) {
        case EFNRequestSerializerTypeJSON:
            return @"EFNRequestSerializerTypeJSON";
            break;
        case EFNRequestSerializerTypePlist:
            return @"EFNRequestSerializerTypePlist";
            break;
        default:
            return @"EFNRequestSerializerTypeHTTP";
            break;
    }
}

- (NSString *)getResponseSerializerType:(EFNResponseSerializerType)type {
    switch (type) {
        case EFNResponseSerializerTypeXML:
            return @"EFNResponseSerializerTypeXML";
            break;
        case EFNResponseSerializerTypePlist:
            return @"EFNResponseSerializerTypePlist";
            break;
        case EFNResponseSerializerTypeJSON:
            return @"EFNResponseSerializerTypeJSON";
            break;
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
        case EFNResponseSerializerTypeXMLDocument:
            return @"EFNResponseSerializerTypeXMLDocument";
            break;
#endif
        default:
            return @"EFNResponseSerializerTypeHTTP";
            break;
    }
}

@end
