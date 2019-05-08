//
//  EFNetworkingGETTests.m
//  EFNetworkingTests
//
//  Created by Dandre on 2018/3/29.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EFNetworking.h"
#import "DemoRequestModel.h"
#import "DemoResponseModel.h"
#import "DemoSignService.h"

@interface EFNetworkingGETTests : XCTestCase

@end

@implementation EFNetworkingGETTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testGETRequest1
{
    [[EFNetHelper shareHelper] request:^(EFNRequest * _Nonnull request) {
        // 当直接设置url时，server和api属性将失效
        request.url = @"http://api.baidu.com/helloword";
        request.HTTPMethod = EFNHTTPMethodGET;
    }
                               success:^(EFNResponse * _Nonnull response) {
                                   EFNLog(@"responseObject:%@",response.dataObject);
                               }
                               failure:^(EFNResponse * _Nonnull response) {
                                   EFNLog(@"error:%@", response.message);
                               }];
}

- (void)testGETRequest2
{
    [[EFNetHelper shareHelper] request:^(EFNRequest * _Nonnull request) {
        request.server = @"http://api.baidu.com";
        request.api = @"helloword";
        request.HTTPMethod = EFNHTTPMethodGET;
    }
                               success:^(EFNResponse * _Nonnull response) {
                                   EFNLog(@"responseObject:%@",response.dataObject);
                               }
                               failure:^(EFNResponse * _Nonnull response) {
                                   EFNLog(@"error:%@", response.message);
                               }];
}

- (void)testGETRequest3
{
    [[EFNetHelper shareHelper] request:^(EFNRequest * _Nonnull request) {
        request.server = @"http://api.baidu.com/helloword";
        request.HTTPMethod = EFNHTTPMethodGET;
        
        // 是否允许缓存
        request.enableCache = YES;
        // 缓存时间 单位 秒
        request.cacheTimeout = 60 * 5;
    }
                               success:^(EFNResponse * _Nonnull response) {
                                   EFNLog(@"responseObject:%@",response.dataObject);
                               }
                               failure:^(EFNResponse * _Nonnull response) {
                                   EFNLog(@"error:%@", response.message);
                               }];
}

- (void)testGetRequest4
{
    [[EFNetHelper shareHelper] request:^(EFNRequest * _Nonnull request) {
        // 此时没有设置单独的 server，会自动读取EFNetHelper当前实例的全局配置
        // 但是当全局配置没有设置server时，就会报出异常
        request.server = @"http://api.baidu.com";
        
        // 设置要请求的API地址，特别需要注意的是:
        // 1.这里的API是可以带URL参数的，如："getUserInfo?type=vip"
        // 2.request.api会和最终的server地址智能拼接，这里API前面带不带“/”都是可以的，如:“getUserInfo” 和 "/getUserInfo"
        request.api = @"getUserInfo";
        
        // Request 默认HTTPMethod为POST，如果不为POST，此处必须手动设置HTTPMethod，否者可能会报错
        request.HTTPMethod = EFNHTTPMethodGET;
        
        // 设置请求的参数，特别说明的是：
        // 1.这里的parameters可以接收 Dictionary或Array或Sting 类型
        // 2.为String格式时，必须为url参数拼接的格式
        request.parameters = @{@"key": @"value"};
        
        // 如果单一接口的Header内容与全局配置的不一致，可以单独在这里设置
        request.headers = @{@"key": @"value"};
        
        // 如果单一接口响应的数据类型 不在全局配置设定的范围，在这里可以单独设置
        request.responseSerializerType = EFNResponseSerializerTypeJSON;
    }
                              progress:^(NSProgress * _Nonnull progress) {
                                  EFNLog(@"progress:%@", progress);
                              }
                               success:^(EFNResponse * _Nonnull response) {
                                   EFNLog(@"responseObject:%@",response.dataObject);
                               }
                               failure:^(EFNResponse * _Nonnull response) {
                                   EFNLog(@"error:%@", response.message);
                               }];
}

/**
 使用请求模型请求示例
 */
- (void)testRequest5
{
    DemoSignService *signService = [[DemoSignService alloc] init];
    DemoRequestModel *req = [[DemoRequestModel alloc] init];
    
    req.signService = signService;
    
    req.server = @"http://api.baidu.com";
    req.api = @"helloworld";
    req.HTTPMethod = EFNHTTPMethodGET;
    
    req.key1 = @"value1";
    req.key2 = @"value2";
    req.keyn = @"valuen";
    
    NSLog(@"req:%@", req);
    
    [EFNetHelper.shareHelper request:req
                            reformer:^id<EFNResponseDataReformer> _Nullable{
                                DemoResponseModel *resModel = [[DemoResponseModel alloc] init];
                                return resModel;
                            }
                            progress:^(NSProgress * _Nonnull progress) {
                                EFNLog(@"progress:%@",progress.localizedDescription);
                            }
                            response:^(DemoResponseModel * reformData, EFNResponse * _Nonnull response) {
                                if (reformData.isSuccess) {
                                    EFNLog(@"请求成功，reformData:%@", reformData);
                                }else{
                                    EFNLog(@"请求失败，error：%@", response.error.localizedDescription);
                                }
                            }];
}

@end

