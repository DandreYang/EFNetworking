//
//  EFNetProxy.m
//  EFNetworking
//
//  Created by Dandre on 2018/3/23.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import "EFNetProxy.h"

@interface EFNetProxy ()
#if _EFN_USE_AFNETWORKING_
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
#endif
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSNumber *, __kindof NSURLSessionTask *> *dispatchPool;

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
}

#pragma mark - GET
#if _EFN_USE_AFNETWORKING_
- (AFHTTPSessionManager *)sessionManager {
    if (!_sessionManager) {
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.operationQueue.maxConcurrentOperationCount = 5;
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
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
#if _EFN_USE_AFNETWORKING_
    return (NSInteger)[AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
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

- (NSString *)getHTTPMethodWithRequest:(EFNRequest *)request
{
    NSString *httpMethod = nil;
    static dispatch_once_t onceToken;
    static NSArray *httpMethodArray = nil;
    dispatch_once(&onceToken, ^{
        httpMethodArray = @[@"POST", @"GET", @"HEAD", @"DELETE", @"PUT", @"PATCH"];
    });
    
    if (request.HTTPMethod >= 0 && request.HTTPMethod < httpMethodArray.count) {
        httpMethod = httpMethodArray[request.HTTPMethod];
    }
    
    NSAssert(httpMethod.length > 0, @"The HTTP method not found.");
    
    return httpMethod;
}

#pragma mark - 配置URLRequest
- (void)configURLRequest:(NSMutableURLRequest *)urlRequest withEFNRequest:(EFNRequest *)request
{
    NSParameterAssert(request);
    
    if (!urlRequest) {
        return;
    }
    
    if (request.headers.count > 0) {
        [request.headers enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
            [urlRequest setValue:value forHTTPHeaderField:field];
        }];
    }
#if _EFN_USE_AFNETWORKING_
    self.sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithSet:request.responseSerializerTypes];
    self.sessionManager.requestSerializer.timeoutInterval = request.timeoutInterval;
#endif
    urlRequest.timeoutInterval = request.timeoutInterval;
}

#pragma mark - Methods
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
        return [self download:request
                     progress:downloadProgressBlock
                      success:successBlock
                      failure:failureBlock];
    }else if (request.requestType == EFNRequestTypeFormDataUpload || request.requestType == EFNRequestTypeStreamUpload) {
        return [self upload:request
                   progress:uploadProgressBlock
                    success:successBlock
                    failure:failureBlock];
    }
    
    NSString *HTTPMethod = [self getHTTPMethodWithRequest:request];
    
    NSError *serializationError = nil;

    NSMutableURLRequest *urlRequest = [self.sessionManager.requestSerializer requestWithMethod:HTTPMethod
                                                                                  URLString:request.url
                                                                                 parameters:request.parameters
                                                                                      error:&serializationError];
    [self configURLRequest:urlRequest withEFNRequest:request];
    
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
                                         uploadProgress:nil
                                       downloadProgress:nil
                                      completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                                          
                                          NSNumber *requestID = @([dataTask taskIdentifier]);
                                          [self.dispatchPool removeObjectForKey:requestID];
                                          
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
    
    self.dispatchPool[requestID] = dataTask;
    [dataTask resume];
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
    
    NSURL *downloadFileSavePathURL = nil;
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
                NSLog(@"EFNetProxy:创建下载路径失败");
                return @(0);
            }
            
            if (!isFile) {
                downloadFileSavePathURL = [NSURL fileURLWithPath:[NSString pathWithComponents:@[request.downloadSavePath, fileName]] isDirectory:NO];
            }
        }
    }
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:request.url]];
    
    [self configURLRequest:urlRequest withEFNRequest:request];
    NSNumber *requestID = nil;
#if _EFN_USE_AFNETWORKING_
    __block NSURLSessionDownloadTask *downloadTask = nil;
    
    NSData *resumeData = nil;
    
    // 判断该下载任务是否允许断点下载 并且本地是否有已下载的原始数据
    if (request.enableResumeDownload) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:downloadFileSavePathURL.absoluteString]) {
            resumeData = [NSData dataWithContentsOfURL:downloadFileSavePathURL];
        }
    }
    // 判断该下载任务是否可以被重新唤起（断点下载）
    BOOL canResume = request.enableResumeDownload && resumeData;
    if (canResume) {
        downloadTask = [self.sessionManager downloadTaskWithResumeData:resumeData
                                                              progress:^(NSProgress * _Nonnull downloadProgress) {
                                                                  EFN_SAFE_BLOCK(progressBlock, downloadProgress);
                                                              }
                                                           destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                               return downloadFileSavePathURL;
                                                           }
                                                     completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                         NSNumber *requestID = @(downloadTask.taskIdentifier);
                                                         [self.dispatchPool removeObjectForKey:requestID];
                                                         
                                                         EFNResponse *efnResponse = [[EFNResponse alloc] initWithRequestID:requestID
                                                                                                                   urlRequest:urlRequest
                                                                                                            responseObject:filePath
                                                                                                                  urlResponse:(NSHTTPURLResponse *)response
                                                                                                                     error:error];
                                                         
                                                         if (error) {
                                                             EFN_SAFE_BLOCK(failureBlock, efnResponse);
                                                         }else{
                                                             EFN_SAFE_BLOCK(successBlock, efnResponse);
                                                         }
                                                     }];
    }else{
        downloadTask = [self.sessionManager downloadTaskWithRequest:urlRequest
                                                           progress:^(NSProgress * _Nonnull downloadProgress) {
                                                               EFN_SAFE_BLOCK(progressBlock, downloadProgress);
                                                           }
                                                        destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                            return downloadFileSavePathURL;
                                                        }
                                                  completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                      
                                                      NSNumber *requestID = @(downloadTask.taskIdentifier);
                                                      [self.dispatchPool removeObjectForKey:requestID];
                                                      
                                                      EFNResponse *efnResponse = [[EFNResponse alloc] initWithRequestID:requestID
                                                                                                                urlRequest:urlRequest
                                                                                                         responseObject:filePath
                                                                                                               urlResponse:(NSHTTPURLResponse *)response
                                                                                                                  error:error];
                                                      
                                                      if (error) {
                                                          EFN_SAFE_BLOCK(failureBlock, efnResponse);
                                                      }else{
                                                          EFN_SAFE_BLOCK(successBlock, efnResponse);
                                                      }

                                                  }];
    }
    
    requestID = @(downloadTask.taskIdentifier);
    
    if (downloadTask && requestID) {
        self.dispatchPool[requestID] = downloadTask;
    }
    [downloadTask resume];
#endif
    
    return requestID;
}

#pragma mark - Upload
- (NSNumber *_Nonnull)upload:(EFNRequest * _Nonnull)request
                    progress:(EFNProgressBlock _Nullable )progressBlock
                     success:(EFNCallBlock _Nullable )successBlock
                     failure:(EFNCallBlock _Nullable )failureBlock
{
    NSParameterAssert(request);
    NSParameterAssert(request.url);
#if _EFN_USE_AFNETWORKING_
    if (request.requestType == EFNRequestTypeFormDataUpload) {
        __block NSURLSessionDataTask *uploadTask = nil;
        uploadTask = [self.sessionManager POST:request.url
                                    parameters:request.parameters
                     constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                         [request.uploadFormDatas enumerateObjectsUsingBlock:^(EFNUploadFormData *obj, NSUInteger idx, BOOL *stop) {
                             if (obj.fileData) {
                                 if (obj.fileName && obj.mimeType) {
                                     [formData appendPartWithFileData:obj.fileData name:obj.name fileName:obj.fileName mimeType:obj.mimeType];
                                 } else {
                                     [formData appendPartWithFormData:obj.fileData name:obj.name];
                                 }
                             } else if (obj.fileURL) {
                                 NSError *fileError = nil;
                                 if (obj.fileName && obj.mimeType) {
                                     [formData appendPartWithFileURL:obj.fileURL name:obj.name fileName:obj.fileName mimeType:obj.mimeType error:&fileError];
                                 } else {
                                     [formData appendPartWithFileURL:obj.fileURL name:obj.name error:&fileError];
                                 }
                                 if (fileError) {
                                     *stop = YES;
                                 }
                             }
                         }];
                     }
                                      progress:^(NSProgress * _Nonnull uploadProgress) {
                                          EFN_SAFE_BLOCK(progressBlock, uploadProgress);
                                      }
                                       success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                           NSNumber *requestID = @(uploadTask.taskIdentifier);
                                           [self.dispatchPool removeObjectForKey:requestID];
                                           
                                           EFNResponse *efnResponse = [[EFNResponse alloc] initWithRequestID:requestID
                                                                                                     urlRequest:task.originalRequest
                                                                                              responseObject:responseObject
                                                                                                    urlResponse:((NSHTTPURLResponse *)task.response)
                                                                                                       error:nil];
                                           
                                           EFN_SAFE_BLOCK(successBlock, efnResponse);
                                       }
                                       failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                           NSNumber *requestID = @(uploadTask.taskIdentifier);
                                           [self.dispatchPool removeObjectForKey:requestID];
                                           
                                           EFNResponse *efnResponse = [[EFNResponse alloc] initWithRequestID:requestID
                                                                                                     urlRequest:task.originalRequest
                                                                                              responseObject:nil
                                                                                                    urlResponse:((NSHTTPURLResponse *)task.response)
                                                                                                       error:error];
                                           
                                           EFN_SAFE_BLOCK(failureBlock, efnResponse);
                                       }];
        
        NSNumber *requestID = @(uploadTask.taskIdentifier);
        
        if (requestID && uploadTask) {
            self.dispatchPool[requestID] = uploadTask;
        }
        [uploadTask resume];
        
        return requestID;
    }else{
        NSAssert(NO, @"暂不支持文件流上传");
        return nil;
    }
#else
    return nil;
#endif
}

#pragma mark - Resume Methods
// 继续所有请求
- (void)resumeAllRequests
{
    [self.dispatchPool.allValues makeObjectsPerformSelector:@selector(resume)];
}

// 继续指定请求
- (void)resumeWithRequestID:(NSNumber *_Nonnull)requestID
{
    if (!requestID) {
        NSLog(@"requestID is nil");
        return;
    }
    NSURLSessionDataTask *requestTask = self.dispatchPool[requestID];
    [requestTask resume];
}

// 批量继续请求
- (void)resumeWithRequestIDList:(NSArray <NSNumber *> *_Nonnull)requestIDList
{
    if (!requestIDList || requestIDList.count == 0) {
        return;
    }
    
    for (NSNumber *requestID in requestIDList) {
        NSURLSessionDataTask *requestTask = self.dispatchPool[requestID];
        [requestTask resume];
    }
}

#pragma mark - Suspend Methods
// 暂停所有请求
- (void)suspendAllRequests
{
    [self.dispatchPool.allValues makeObjectsPerformSelector:@selector(suspend)];
}

// 暂停指定请求
- (void)suspendWithRequestID:(NSNumber *_Nonnull)requestID
{
    if (!requestID) {
        NSLog(@"requestID is nil");
        return;
    }
    NSURLSessionDataTask *requestTask = self.dispatchPool[requestID];
    [requestTask suspend];
}

// 批量暂停请求
- (void)suspendWithRequestIDList:(NSArray <NSNumber *> *_Nonnull)requestIDList
{
    if (!requestIDList || requestIDList.count == 0) {
        return;
    }
    
    for (NSNumber *requestID in requestIDList) {
        NSURLSessionDataTask *requestTask = self.dispatchPool[requestID];
        [requestTask suspend];
    }
}

#pragma mark - Cancel Methods
// 取消所有请求
- (void)cancelAllRequests
{
    [self.dispatchPool.allValues makeObjectsPerformSelector:@selector(cancel)];
    [self.dispatchPool removeAllObjects];
}

// 取消指定请求
- (void)cancelWithRequestID:(NSNumber *)requestID
{
    if (!requestID) {
        NSLog(@"requestID is nil");
        return;
    }
    [self.dispatchPool[requestID] cancel];
    [self.dispatchPool removeObjectForKey:requestID];
}

// 批量取消请求
- (void)cancelWithRequestIDList:(NSArray <NSNumber *> *)requestIDList
{
    if (!requestIDList || requestIDList.count == 0) {
        return;
    }
    
    for (NSNumber *requestID in requestIDList) {
        NSURLSessionDataTask *requestTask = self.dispatchPool[requestID];
        [requestTask cancel];
    }

    [self.dispatchPool removeObjectsForKeys:requestIDList];
}

@end
