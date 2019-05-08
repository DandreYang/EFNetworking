//
//  EFNetworkingPOSTTests.m
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

@interface EFNetworkingPOSTTests : XCTestCase

@end

@implementation EFNetworkingPOSTTests

- (void)setUp {
    [super setUp];
    
#pragma mark - 模拟全局配置
    // 这里设置的config实际上是一个单例，默认对EFNetHelper的实例化对象都会有效，除非单独给对应的EFNetHelper实例赋值新的config代理
    [EFNetHelper generalConfigHandler:^(id<EFNGeneralConfigDelegate>  _Nonnull config) {
        
        // 设置全局签名代理
        config.signService = [[DemoSignService alloc] init];
        // 设置全局服务地址
        config.generalServer = @"http://api.abc.com";
        // 设置全局Headers
        config.generalHeaders = @{@"HeaderKey":@"HeaderValue"};
        // 设置通用参数
        config.generalParameters = @{@"generalParameterKey":@"generalParameterValue"};
        // 设置全局支持响应的数据类型
        config.generalResponseSerializerType = EFNResponseSerializerTypeJSON;
        
        // 这里设置的下载文件保存路径是对全局有效的，所以建议设置的路径是指定到文件夹而不是文件，否则后下载的文件会将之前下载的文件进行覆盖
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = paths.firstObject;
        
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"/General/Download"];
        config.generalDownloadSavePath = path;
    }];
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

- (void)testPOSTRequest1
{
    [[EFNetHelper shareHelper] request:^(EFNRequest * _Nonnull request) {
        request.url = @"http://baidu.com/helloword";
        request.HTTPMethod = EFNHTTPMethodPOST;     // Request 默认HTTPMethod为POST，如果为POST，此句代码可不写
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

- (void)testPOSTRequest2
{
    [[EFNetHelper shareHelper] request:^(EFNRequest * _Nonnull request) {
        request.server = @"http://baidu.com";
        request.api = @"helloword";
        request.HTTPMethod = EFNHTTPMethodPOST;     // Request 默认HTTPMethod为POST，如果为POST，此句代码可不写
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

- (void)testPOSTRequest3
{
    [[EFNetHelper shareHelper] request:^(EFNRequest * _Nonnull request) {
        // 此时没有设置单独的 server，会自动读取EFNetHelper当前实例的全局配置
        request.api = @"helloword";
        request.HTTPMethod = EFNHTTPMethodPOST;     // Request 默认HTTPMethod为POST，如果为POST，此句代码可不写
        request.parameters = @{@"key": @"value"};
        request.headers = @{@"key": @"value"};
        request.requestSerializerType = EFNRequestSerializerTypeHTTP;
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
- (void)testRequest4
{
    DemoSignService *signService = [[DemoSignService alloc] init];
    DemoRequestModel *req = [[DemoRequestModel alloc] init];
    
    req.signService = signService;
    
    // 此时没有设置单独的 server，会自动读取EFNetHelper当前实例的全局配置
    // req.server = @"http://api.baidu.com";
    req.api = @"helloworld";
    req.HTTPMethod = EFNHTTPMethodPOST;
    
    req.key1 = @"value1";
    req.key2 = @"value2";
    req.keyn = @"valuen";
    
    EFNLog(@"req:%@", req);
    
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
