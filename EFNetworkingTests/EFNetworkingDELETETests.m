//
//  EFNetworkingDELETETests.m
//  EFNetworkingTests
//
//  Created by Dandre on 2018/3/29.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EFNetworking.h"

@interface EFNetworkingDELETETests : XCTestCase

@end

@implementation EFNetworkingDELETETests

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

- (void)testDELETERequest1
{
    [[EFNetHelper shareHelper] request:^(EFNRequest * _Nonnull request) {
        // 此时没有设置单独的 server，会自动读取EFNetHelper当前实例的全局配置
        request.server = @"http://api.baidu.com";
        request.api = @"helloword";
        request.HTTPMethod = EFNHTTPMethodDELETE;
        request.parameters = @{@"id": @(100)};
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
