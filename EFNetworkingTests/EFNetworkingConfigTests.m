//
//  EFNetworkingTests.m
//  EFNetworkingTests
//
//  Created by Dandre on 2018/3/29.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EFNetworking.h"
#import "DemoSignService.h"

@interface EFNetworkingTests : XCTestCase

@end

@implementation EFNetworkingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testConfig
{
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

- (void)testNetHelper
{
    EFNetHelper *shareHelper = EFNetHelper.shareHelper;
    EFNetHelper *newHelper = EFNetHelper.helper;
    EFNLog(@"\n shareNetHelper:%p \n newNetHelper:%p \n shareNetHelper.config:%p \n newNetHelper.config:%p",
           shareHelper,newHelper,shareHelper.config,newHelper.config);
}

@end
