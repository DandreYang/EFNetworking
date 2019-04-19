//
//  EFNResponse.m
//  EFNetworking
//
//  Created by Dandre on 2018/3/28.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import "EFNResponse.h"

@interface EFNResponse ()

@property (nonatomic, assign, readwrite) EFNResponseStatus status;
@property (nonatomic, copy, readwrite) NSNumber *requestID;
@property (nonatomic, assign, readwrite) NSInteger statusCode;
@property (nonatomic, copy, readwrite) NSString *message;
@property (nonatomic, strong, readwrite) id dataObject;
@property (nonatomic, copy, readwrite) NSURLRequest *urlRequest;
@property (nonatomic, strong, readwrite) NSHTTPURLResponse *urlResponse;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, assign, readwrite) BOOL isCache;

@end

@implementation EFNResponse

- (NSString *)description
{
    return [[NSString alloc] initWithFormat:@"\n状态吗: %zd,\n错误: %@,\n响应: %@,\n响应体: %@", self.statusCode, self.error, self.urlResponse, self.dataObject];
}

- (void)setError:(NSError *)error
{
    _error = error;
    _statusCode = error.code;
    _message = error.localizedDescription;
}

- (NSInteger)statusCode
{
    return _statusCode?:self.urlResponse.statusCode;
}

#pragma mark - life cycle
- (instancetype)initWithRequestID:(NSNumber *)requestID
                       urlRequest:(NSURLRequest *)urlRequest
                   responseObject:(id)dataObject
                      urlResponse:(NSHTTPURLResponse *)response
                            error:(NSError *)error
{
    self = [super init];
    if (self) {
        self.requestID = requestID;
        self.urlRequest = urlRequest;
        self.urlResponse = response;
        self.isCache = NO;
        self.dataObject = dataObject;
        self.status = [self responseStatusWithError:error];
        self.error = error;
    }
    return self;
}

- (instancetype)initWithCacheObject:(id<NSCoding>)cacheObject
{
    self = [super init];
    if (self) {
        self.status = [self responseStatusWithError:nil];
        self.requestID = @(0);
        self.urlRequest = nil;
        self.dataObject = cacheObject;
        self.isCache = YES;
    }
    return self;
}

#pragma mark - private methods
- (EFNResponseStatus)responseStatusWithError:(NSError *)error
{
    if (error) {
        EFNResponseStatus result = EFNResponseStatusErrorNoNetwork;

        if (error.code == NSURLErrorTimedOut) {
            result = EFNResponseStatusErrorTimeout;
        }else if (error.code == NSURLErrorCancelled) {
            result = EFNResponseStatusErrorCancel;
        }

        return result;
    } else {
        return EFNResponseStatusSuccess;
    }
}

@end
