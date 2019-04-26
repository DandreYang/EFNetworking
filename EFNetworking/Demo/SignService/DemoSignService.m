//
//  DemoSignService.m
//  EFNetworking
//
//  Created by Dandre on 2018/4/12.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import "DemoSignService.h"
#import "EFNetHelper.h"
#import "NSString+EFNetworking.h"

@implementation DemoSignService

#pragma mark - 设置加密签名
/**
 此处可设置统一签名规则
 - 如有不同的服务接口使用不同的签名规则，可通过遵循 EFNSignService 协议进行自定义，同时，设置 EFNetHelper对象的config.signService属性为该对象
 - 如果单个接口的签名与统一配置的签名不同，例如使用的一些第三方平台的API，这种情况也可以自定义对应的签名代理，然后赋值给对应EFNRequest对象的signService属性
 
 @param request 请求的Request
 @return 签名内容
 */
- (NSDictionary<NSString *,NSString *> *)signForRequest:(EFNRequest *)request
{
    /// 获取HTTPMethod
    //NSString *httpMethod = request.HTTPMethod;
    /// 获取APIMethod
    //NSString *apiMethod = [EFNetHelper getApiMethodWithRequest:request];
    
    NSMutableDictionary *signDict = @{}.mutableCopy;
    
    // 在此处自定义签名内容即可。
    
    return signDict.copy;
}

@end
