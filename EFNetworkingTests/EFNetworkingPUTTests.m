//
//  EFNetworkingPUTTests.m
//  EFNetworkingTests
//
//  Created by Dandre on 2018/3/29.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EFNetworking.h"

@interface EFNetworkingPUTTests : XCTestCase

@end

@implementation EFNetworkingPUTTests

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

- (void)testPUTRequest1
{
    [[EFNetHelper shareHelper] request:^(EFNRequest * _Nonnull request) {
        // 此时没有设置单独的 server，会自动读取EFNetHelper当前实例的全局配置
        request.server = @"http://api.baidu.com";
        request.api = @"helloword";
        request.HTTPMethod = EFNHTTPMethodPUT;     
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

@end
