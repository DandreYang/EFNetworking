//
//  EFNetProxy.m
//  EFNetworking
//
//  Created by Dandre on 2018/3/23.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import "EFNetProxy.h"
#ifndef _EFN_USE_AFNETWORKING_
#define _EFN_USE_AFNETWORKING_ 1
#endif

#if _EFN_USE_AFNETWORKING_
#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif
#endif

#define Lock() [self.lock lock]
#define Unlock() [self.lock unlock]

static NSString * const EFNetProxyLockName = @"vip.dandre.EFNetworking.NetProxy.lock";

static NSString *EFNDownloadTempCacheFolder(){
    NSFileManager *fileManager = [NSFileManager defaultManager];
    static NSString *cacheFolder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cacheFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:@"EFNetworking"];
    });
    NSError *error;
    if (![fileManager fileExistsAtPath:cacheFolder]) {
        [fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (error) {
        EFNLog(@"Failed to create download cache folder at %@, error => %@", cacheFolder, error.localizedDescription);
        return nil;
    }
    
    return cacheFolder;
}

static NSURL * EFNDownloadTempPath(NSString * fileName) {
    NSString *tmpPath = [EFNDownloadTempCacheFolder() stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:tmpPath];
}

@interface EFNetProxy ()
#if _EFN_USE_AFNETWORKING_
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
#endif
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSNumber *, __kindof NSURLSessionTask *> *dispatchPool;
@property (nonatomic, strong) NSLock *lock;

@end

@implementation EFNetProxy

#pragma mark - Life Cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _enableHTTPS = YES;
        _validatesDomainName = NO;
        _allowInvalidCertificates = YES;
    }
    return self;
}

+ (instancetype)shareProxy
{
    static id proxy = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        proxy = [[self alloc] init];
    });
    
    return proxy;
}

+ (instancetype)newProxy
{
    return [[self alloc] init];
}

- (void)dealloc
{
    [self cancelAllRequests];
    _dispatchPool = nil;
    _lock = nil;
    _sessionManager = nil;
}

- (NSLock *)lock {
    if (!_lock) {
        _lock = [[NSLock alloc] init];
        _lock.name = EFNetProxyLockName;
    }
    
    return _lock;
}

#pragma mark - GET
#if _EFN_USE_AFNETWORKING_
- (AFHTTPSessionManager *)sessionManager {
    if (!_sessionManager) {
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.operationQueue.maxConcurrentOperationCount = 5;
    }
    
    if (_enableHTTPS) {
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
        securityPolicy.allowInvalidCertificates = _allowInvalidCertificates;
        securityPolicy.validatesDomainName = _validatesDomainName;
        _sessionManager.securityPolicy = securityPolicy;
    }
    
    return _sessionManager;
}
#endif
- (NSMutableDictionary<NSNumber *, __kindof NSURLSessionTask *> *)dispatchPool
{
    if (!_dispatchPool) {
        _dispatchPool = @{}.mutableCopy;
    }
    
    return _dispatchPool;
}

- (EFNReachableStatus)reachabilityStatus
{
#if _EFN_USE_AFNETWORKING_ && !TARGET_OS_WATCH
    return (EFNReachableStatus)[AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
#else
    return EFNReachableStatusNotReachable;
#endif
}

- (__kindof NSURLSessionTask *)taskForRequestID:(NSNumber *)requestID
{
    __block NSURLSessionTask *task = nil;
#if _EFN_USE_AFNETWORKING_
    [self.sessionManager.tasks enumerateObjectsUsingBlock:^(NSURLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.taskIdentifier == requestID.integerValue) {
            task =  obj;
            *stop = YES;
        }
    }];
#endif
    
    return task;
}

#pragma mark - SSL PinnedCertificates
- (void)addSSLPinningCert:(NSData *)cert {
    NSParameterAssert(cert);
#if _EFN_USE_AFNETWORKING_
    NSMutableSet *certSet;
    
    if (self.sessionManager.securityPolicy.pinnedCertificates.count > 0) {
        certSet = [NSMutableSet setWithSet:self.sessionManager.securityPolicy.pinnedCertificates];
    } else {
        certSet = [NSMutableSet set];
    }
    
    [certSet addObject:cert];
    [self.sessionManager.securityPolicy setPinnedCertificates:certSet];
#endif
}

#pragma mark - Request Methods
- (NSNumber *_Nonnull)request:(EFNRequest * _Nonnull)request
               uploadProgress:(EFNProgressBlock)uploadProgressBlock
             downloadProgress:(EFNProgressBlock)downloadProgressBlock
                      success:(EFNCallBlock _Nullable )successBlock
                      failure:(EFNCallBlock _Nullable )failureBlock
{
    NSParameterAssert(request);
    NSParameterAssert(request.url);
    NSNumber *requestID = nil;
    
#if _EFN_USE_AFNETWORKING_
    if (request.requestType == EFNRequestTypeDownload) {
        requestID = [self download:request
                          progress:downloadProgressBlock
                           success:successBlock
                           failure:failureBlock];
        return requestID;
    }else if (request.requestType == EFNRequestTypeFormDataUpload || request.requestType == EFNRequestTypeStreamUpload) {
        requestID =  [self upload:request
                         progress:uploadProgressBlock
                          success:successBlock
                          failure:failureBlock];
        return requestID;
    }
    
    NSError *serializationError = nil;
    NSMutableURLRequest *urlRequest = [self urlRequestForEFNRequest:request error:&serializationError];
    
    if (serializationError) {
        if (failureBlock) {
            EFNResponse *response = [[EFNResponse alloc] initWithRequestID:nil
                                                                   urlRequest:urlRequest
                                                            responseObject:nil
                                                                  urlResponse:nil
                                                                     error:serializationError];
            dispatch_async(self.sessionManager.completionQueue ?: dispatch_get_main_queue(), ^{
                failureBlock(response);
            });
        }
        
        return nil;
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self.sessionManager dataTaskWithRequest:urlRequest
                                         uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
                                             EFN_SAFE_BLOCK(uploadProgressBlock, uploadProgress);
                                         }
                                       downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
                                           EFN_SAFE_BLOCK(downloadProgressBlock, downloadProgress);
                                       }
                                      completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                                          
                                          NSNumber *requestID = @([dataTask taskIdentifier]);
                                          Lock();
                                          [self.dispatchPool removeObjectForKey:requestID];
                                          Unlock();
                                          
                                          EFNResponse *efnResponse = [[EFNResponse alloc] initWithRequestID:requestID
                                                                                                    urlRequest:urlRequest
                                                                                             responseObject:responseObject
                                                                                                   urlResponse:(NSHTTPURLResponse *)response
                                                                                                      error:error];
                                          
                                          if (error) {
                                              EFN_SAFE_BLOCK(failureBlock, efnResponse);
                                          } else {
                                              EFN_SAFE_BLOCK(successBlock, efnResponse);
                                          }
                                      }];
    
    requestID = @([dataTask taskIdentifier]);
    
    if (dataTask && requestID) {
        Lock();
        self.dispatchPool[requestID] = dataTask;
        Unlock();
        [dataTask resume];
    }
#endif
    return requestID;
}

#pragma mark - Download
- (NSNumber *_Nonnull)download:(EFNRequest * _Nonnull)request
                      progress:(EFNProgressBlock _Nullable )progressBlock
                       success:(EFNCallBlock _Nullable )successBlock
                       failure:(EFNCallBlock _Nullable )failureBlock
{
    NSParameterAssert(request);
    NSParameterAssert(request.url);
    NSParameterAssert(request.downloadSavePath);
    
    __block NSURL *downloadFileSavePathURL = nil;
    BOOL isDirectory;
    if(![[NSFileManager defaultManager] fileExistsAtPath:request.downloadSavePath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    
    NSString *fileName = [request.url.lastPathComponent componentsSeparatedByString:@"?"].firstObject;
    
    if (isDirectory) {
        downloadFileSavePathURL = [NSURL fileURLWithPath:[NSString pathWithComponents:@[request.downloadSavePath, fileName]] isDirectory:NO];
    } else {
        downloadFileSavePathURL = [NSURL fileURLWithPath:request.downloadSavePath isDirectory:NO];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:request.downloadSavePath]) {
            
            BOOL isFile = [request.downloadSavePath.lastPathComponent containsString:@"."];
            
            NSString *path = request.downloadSavePath;
            if (isFile) {
                path = [request.downloadSavePath stringByDeletingLastPathComponent];
            }
            
            BOOL createSuccess = [[NSFileManager defaultManager]  createDirectoryAtPath:path
                                                           withIntermediateDirectories:YES
                                                                            attributes:nil
                                                                                 error:nil];
            if (!createSuccess) {
                EFNLog(@"EFNetProxy:创建下载路径失败");
                return @(0);
            }
            
            if (!isFile) {
                downloadFileSavePathURL = [NSURL fileURLWithPath:[NSString pathWithComponents:@[request.downloadSavePath, fileName]] isDirectory:NO];
            }
        }
    }
    
    NSNumber *requestID = nil;
    NSError *serializationError = nil;
    NSMutableURLRequest *urlRequest = [self urlRequestForEFNRequest:request error:&serializationError];
    
    if (serializationError) {
        if (failureBlock) {
            EFNResponse *response = [[EFNResponse alloc] initWithRequestID:nil
                                                                urlRequest:urlRequest
                                                            responseObject:nil
                                                               urlResponse:nil
                                                                     error:serializationError];
            dispatch_async(self.sessionManager.completionQueue ?: dispatch_get_main_queue(), ^{
                failureBlock(response);
            });
        }
        
        return nil;
    }
    
#if _EFN_USE_AFNETWORKING_
    
    /// 统一处理回调
    void (^completionBlock)(__kindof NSURLSessionTask *task, id responseObject, NSError *error) = ^(__kindof NSURLSessionTask *task, id responseObject, NSError *error) {
        NSNumber *requestID = @(task.taskIdentifier);
        Lock();
        [self.dispatchPool removeObjectForKey:requestID];
        Unlock();
        
        EFNResponse *efnResponse = [[EFNResponse alloc] initWithRequestID:requestID
                                                               urlRequest:task.originalRequest
                                                           responseObject:responseObject
                                                              urlResponse:(NSHTTPURLResponse *)task.response
                                                                    error:error];
        
        if (error) {
            EFN_SAFE_BLOCK(failureBlock, efnResponse);
        } else {
            EFN_SAFE_BLOCK(successBlock, efnResponse);
        }
    };

    __block NSURLSessionDownloadTask *downloadTask = nil;
    
    NSData *resumeData = nil;
    
    // 判断该下载任务是否允许断点下载 并且本地是否有已下载的原始数据
    if (request.enableResumeDownload) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:downloadFileSavePathURL.path]) {
            resumeData = [NSData dataWithContentsOfURL:downloadFileSavePathURL];
            [[NSFileManager defaultManager] removeItemAtPath:downloadFileSavePathURL.path error:nil];
        }
    }
    // 判断该下载任务是否可以被重新唤起（断点下载）
    BOOL canResume = request.enableResumeDownload && resumeData && [resumeData length] > 0;
    BOOL resumeDownloadSuccess = NO;
    if (canResume) {
        @try {
            resumeDownloadSuccess = YES;
            downloadTask = [self.sessionManager downloadTaskWithResumeData:resumeData
                                                                  progress:^(NSProgress * _Nonnull downloadProgress) {
                                                                      EFN_SAFE_BLOCK(progressBlock, downloadProgress);
                                                                  }
                                                               destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                   EFNLog(@"targetPath:%@\ndownloadPath:%@", targetPath, downloadFileSavePathURL);
                                                                   return downloadFileSavePathURL;
                                                               }
                                                         completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                             completionBlock(downloadTask, filePath, error);
                                                         }];
        } @catch (NSException *exception) {
            resumeDownloadSuccess = NO;
            EFNLog(@"断点下载失败，失败原因：%@", exception.reason);
        }
    }
    
    if (!resumeDownloadSuccess) {
        downloadTask = [self.sessionManager downloadTaskWithRequest:urlRequest
                                                           progress:^(NSProgress * _Nonnull downloadProgress) {
                                                               EFN_SAFE_BLOCK(progressBlock, downloadProgress);
                                                           }
                                                        destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                            return downloadFileSavePathURL;
                                                        }
                                                  completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                      completionBlock(downloadTask, filePath, error);
                                                  }];
    }
    
    requestID = @(downloadTask.taskIdentifier);
    
    if (downloadTask && requestID) {
        Lock();
        self.dispatchPool[requestID] = downloadTask;
        Unlock();
        [downloadTask resume];
    }
#endif
    
    return requestID;
}

#pragma mark - Upload Methods
- (NSNumber *_Nonnull)upload:(EFNRequest * _Nonnull)request
                    progress:(EFNProgressBlock _Nullable )progressBlock
                     success:(EFNCallBlock _Nullable )successBlock
                     failure:(EFNCallBlock _Nullable )failureBlock
{
    NSParameterAssert(request);
    NSParameterAssert(request.url);
    NSAssert(request.requestType == EFNRequestTypeFormDataUpload || request.requestType == EFNRequestTypeStreamUpload, @"不支持的文件上传类型");
    NSAssert(request.uploadFormDatas.count > 0, @"上传的文件数据不能为空");
    /// 统一处理回调
    void (^completionBlock)(__kindof NSURLSessionTask *task, id responseObject, NSError *error) = ^(__kindof NSURLSessionTask *task, id responseObject, NSError *error) {
        NSNumber *requestID = @(task.taskIdentifier);
        Lock();
        [self.dispatchPool removeObjectForKey:requestID];
        Unlock();
        
        EFNResponse *efnResponse = [[EFNResponse alloc] initWithRequestID:requestID
                                                               urlRequest:task.originalRequest
                                                           responseObject:responseObject
                                                              urlResponse:(NSHTTPURLResponse *)task.response
                                                                    error:error];
        
        if (error) {
            EFN_SAFE_BLOCK(failureBlock, efnResponse);
        } else {
            EFN_SAFE_BLOCK(successBlock, efnResponse);
        }
    };
    
#if _EFN_USE_AFNETWORKING_
    
    NSError *serializationError = nil;
    NSMutableURLRequest *urlRequest = nil;

    urlRequest = [self urlRequestForEFNRequest:request error:&serializationError];
    
    if (serializationError) {
        if (failureBlock) {
            EFNResponse *response = [[EFNResponse alloc] initWithRequestID:nil
                                                                urlRequest:urlRequest
                                                            responseObject:nil
                                                               urlResponse:nil
                                                                     error:serializationError];
            dispatch_async(self.sessionManager.completionQueue ?: dispatch_get_main_queue(), ^{
                failureBlock(response);
            });
        }
        
        return nil;
    }
    
    __block NSURLSessionUploadTask *uploadTask = nil;
    
    if (request.requestType == EFNRequestTypeFormDataUpload) {
        uploadTask = [self.sessionManager uploadTaskWithStreamedRequest:urlRequest
                                                               progress:progressBlock
                                                      completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                                          completionBlock(uploadTask, responseObject, error);
                                                      }];
    } else {
        
        __block EFNMutipartFormData *uploadData = nil;
        [request.uploadFormDatas enumerateObjectsUsingBlock:^(__kindof EFNUploadData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isMemberOfClass:[EFNUploadData class]]) {
                uploadData = obj;
                *stop = YES;
            }
        }];
        
        if (!uploadData) {
            EFNLog(@"upload data must not be nil");
            return nil;
        }
        
        if (uploadData.fileURL) {
            uploadTask = [self.sessionManager uploadTaskWithRequest:urlRequest
                                                           fromFile:uploadData.fileURL
                                                           progress:progressBlock
                                                  completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                                      completionBlock(uploadTask, responseObject, error);
                                                  }];
        } else {
            uploadTask = [self.sessionManager uploadTaskWithRequest:urlRequest
                                                           fromData:uploadData.fileData
                                                           progress:progressBlock
                                                  completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                                      completionBlock(uploadTask, responseObject, error);
                                                  }];
        }
    }
    
    NSNumber *requestID = @(uploadTask.taskIdentifier);
    
    if (requestID && uploadTask) {
        Lock();
        self.dispatchPool[requestID] = uploadTask;
        Unlock();
        [uploadTask resume];
    }
    
    return requestID;
#else
    return nil;
#endif
}

#pragma mark - Resume Methods
// 继续所有请求
- (void)resumeAllRequests
{
    Lock();
    [self.dispatchPool.allValues makeObjectsPerformSelector:@selector(resume)];
    Unlock();
}

// 继续指定请求
- (void)resumeWithRequestID:(NSNumber *_Nonnull)requestID
{
    if (!requestID) {
        EFNLog(@"requestID is nil");
        return;
    }
    Lock();
    NSURLSessionDataTask *requestTask = self.dispatchPool[requestID];
    [requestTask resume];
    Unlock();
}

// 批量继续请求
- (void)resumeWithRequestIDList:(NSArray <NSNumber *> *_Nonnull)requestIDList
{
    if (!requestIDList || requestIDList.count == 0) {
        return;
    }
    
    for (NSNumber *requestID in requestIDList) {
        Lock();
        NSURLSessionDataTask *requestTask = self.dispatchPool[requestID];
        [requestTask resume];
        Unlock();
    }
}

#pragma mark - Suspend Methods
// 暂停所有请求
- (void)suspendAllRequests
{
    Lock();
    [self.dispatchPool.allValues makeObjectsPerformSelector:@selector(suspend)];
    Unlock();
}

// 暂停指定请求
- (void)suspendWithRequestID:(NSNumber *_Nonnull)requestID
{
    if (!requestID) {
        EFNLog(@"requestID is nil");
        return;
    }
    Lock();
    NSURLSessionDataTask *requestTask = self.dispatchPool[requestID];
    [requestTask suspend];
    Unlock();
}

// 批量暂停请求
- (void)suspendWithRequestIDList:(NSArray <NSNumber *> *_Nonnull)requestIDList
{
    if (!requestIDList || requestIDList.count == 0) {
        return;
    }
    
    for (NSNumber *requestID in requestIDList) {
        Lock();
        NSURLSessionDataTask *requestTask = self.dispatchPool[requestID];
        [requestTask suspend];
        Unlock();
    }
}

#pragma mark - Cancel Methods
// 取消所有请求
- (void)cancelAllRequests
{
    Lock();
    [self.dispatchPool.allValues makeObjectsPerformSelector:@selector(cancel)];
    [self.dispatchPool removeAllObjects];
    Unlock();
}

// 取消指定请求
- (void)cancelWithRequestID:(NSNumber *)requestID
{
    if (!requestID) {
        EFNLog(@"requestID is nil");
        return;
    }
    Lock();
    [self.dispatchPool[requestID] cancel];
    [self.dispatchPool removeObjectForKey:requestID];
    Unlock();
}

// 批量取消请求
- (void)cancelWithRequestIDList:(NSArray <NSNumber *> *)requestIDList
{
    if (!requestIDList || requestIDList.count == 0) {
        return;
    }
    
    for (NSNumber *requestID in requestIDList) {
        Lock();
        NSURLSessionDataTask *requestTask = self.dispatchPool[requestID];
        Unlock();
        [requestTask cancel];
    }
    
    Lock();
    [self.dispatchPool removeObjectsForKeys:requestIDList];
    Unlock();
}

#pragma mark - Private Methods

#pragma mark 获取 requestSerializer
- (__kindof NSObject *)requestSerializerForRequest:(EFNRequest *)request
{
#if _EFN_USE_AFNETWORKING_
    AFHTTPRequestSerializer *requestSerializer = nil;
    switch (request.requestSerializerType) {
        case EFNRequestSerializerTypeJSON:
            requestSerializer = [AFJSONRequestSerializer serializer];
            break;
        case EFNRequestSerializerTypePlist:
            requestSerializer = [AFPropertyListRequestSerializer serializer];
            break;
        default:
            requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
    }
    
    requestSerializer.timeoutInterval = request.timeoutInterval;
    
    if (request.headers.count > 0) {
        [request.headers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull field, NSString * _Nonnull value, BOOL * _Nonnull stop) {
            [requestSerializer setValue:value forHTTPHeaderField:field];
        }];
    }
    
    return requestSerializer;
#else
    return nil;
#endif
}

#pragma mark - 获取 responseSerializer
- (__kindof NSObject *)responseSerializerForRequest:(EFNRequest *)request
{
#if _EFN_USE_AFNETWORKING_
    AFHTTPResponseSerializer *responseSerializer = nil;
    switch (request.responseSerializerType) {
        case EFNResponseSerializerTypeJSON:
            responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        case EFNResponseSerializerTypeXML:

            break;
        case EFNResponseSerializerTypePlist:
            responseSerializer = [AFPropertyListResponseSerializer serializer];
            break;
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
        case EFNResponseSerializerTypeXML:
            responseSerializer = [AFXMLDocumentResponseSerializer serializer];
            break;
#endif
        default:
            responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
    }
    
    return responseSerializer;
#else
    return nil;
#endif
}

- (NSMutableURLRequest *)urlRequestForEFNRequest:(EFNRequest *)request error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request.HTTPMethod);
    NSParameterAssert(request.url);
    
    self.sessionManager.requestSerializer = [self requestSerializerForRequest:request];
    self.sessionManager.responseSerializer = [self responseSerializerForRequest:request];
    
    NSMutableURLRequest *urlRequest = nil;
#if _EFN_USE_AFNETWORKING_
    switch (request.requestType) {
        case EFNRequestTypeFormDataUpload:
        {
            urlRequest = [self.sessionManager.requestSerializer multipartFormRequestWithMethod:@"POST"
                                                                                     URLString:request.url
                                                                                    parameters:(NSDictionary *)request.parameters
                                                                     constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                                                                         [request.uploadFormDatas enumerateObjectsUsingBlock:^(__kindof EFNUploadData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                                                             
                                                                             if ([obj isKindOfClass:[EFNMutipartFormData class]]) {
                                                                                 EFNMutipartFormData *item = (EFNMutipartFormData *)obj;
                                                                                 if (item.fileData) {
                                                                                     if (item.fileName && item.mimeType) {
                                                                                         [formData appendPartWithFileData:item.fileData name:item.name fileName:item.fileName mimeType:item.mimeType];
                                                                                     } else {
                                                                                         [formData appendPartWithFormData:item.fileData name:item.name];
                                                                                     }
                                                                                 } else if (item.fileURL) {
                                                                                     NSError *fileError = nil;
                                                                                     if (item.fileName && item.mimeType) {
                                                                                         [formData appendPartWithFileURL:item.fileURL name:item.name fileName:item.fileName mimeType:item.mimeType error:&fileError];
                                                                                     } else {
                                                                                         [formData appendPartWithFileURL:item.fileURL name:item.name error:&fileError];
                                                                                     }
                                                                                     if (fileError) {
                                                                                         *stop = YES;
                                                                                     }
                                                                                 }
                                                                             }
                                                                         }];
                                                                     } error:error];
        }
            break;
        case EFNRequestTypeDownload:
            urlRequest = [self.sessionManager.requestSerializer requestWithMethod:@"GET"
                                                                        URLString:request.url
                                                                       parameters:request.parameters
                                                                            error:error];
            break;
        default:
            urlRequest = [self.sessionManager.requestSerializer requestWithMethod:request.HTTPMethod
                                                                        URLString:request.url
                                                                       parameters:request.parameters
                                                                            error:error];
            break;
    }
#endif
    
    return urlRequest;
}

@end
