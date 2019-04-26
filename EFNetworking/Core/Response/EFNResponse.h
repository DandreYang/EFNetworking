//
//  EFNResponse.h
//  EFNetworking
//
//  Created by Dandre on 2018/3/28.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 响应状态
 */
typedef NS_ENUM(NSUInteger, EFNResponseStatus)
{
    EFNResponseStatusSuccess        = 0,    //!< 响应成功
    EFNResponseStatusErrorTimeout   = -1,   //!< 请求超时
    EFNResponseStatusErrorCancel    = -2,   //!< 取消请求
    EFNResponseStatusErrorNoNetwork = -3    //!< 无网络
};

/**
 响应数据
 */
@interface EFNResponse : NSObject

/// 状态
@property (nonatomic, assign, readonly) EFNResponseStatus status;

/// 请求的编号
@property (nonatomic, copy, readonly) NSNumber *requestID;

/// 状态码
@property (nonatomic, assign, readonly) NSInteger statusCode;

/// 错误提示
@property (nonatomic, copy, readonly) NSString *message;

/// 响应体数据对象
@property (nonatomic, strong, readonly) id<NSCoding> dataObject;

/// 请求的urlRequest
@property (nonatomic, copy, readonly) NSURLRequest *urlRequest;

/// 响应数据
@property (nonatomic, strong, readonly) NSHTTPURLResponse *urlResponse;

/// 错误信息
@property (nonatomic, strong, readonly) NSError *error;

/// 是否是缓存
@property (nonatomic, assign, readonly) BOOL isCache;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 实例方法

 @param requestID 请求的任务编号
 @param urlRequest 请求体
 @param dataObject 返回的数据
 @param urlResponse 响应体
 @param error 错误
 @return 实例
 */
- (instancetype)initWithRequestID:(NSNumber *)requestID
                       urlRequest:(NSURLRequest *)urlRequest
                   responseObject:(id)dataObject
                      urlResponse:(NSHTTPURLResponse *)urlResponse
                            error:(NSError *)error NS_DESIGNATED_INITIALIZER;

/**
 通过缓存实例对象

 @param cacheObject 缓存对象
 @return 实例
 */
- (instancetype)initWithCacheObject:(id<NSCoding>)cacheObject NS_DESIGNATED_INITIALIZER;

@end
