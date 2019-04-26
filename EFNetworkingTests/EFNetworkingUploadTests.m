//
//  EFNetworkingUploadTests.m
//  EFNetworkingTests
//
//  Created by Dandre on 2018/3/29.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EFNetworking.h"

@interface EFNetworkingUploadTests : XCTestCase

@end

@implementation EFNetworkingUploadTests

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

- (void)testFormDataUploadRequest
{
    [[EFNetHelper shareHelper] request:^(EFNRequest * _Nonnull request) {
        
        // 设置上传服务地址
        request.server = @"http://api.baidu.com";
        request.api = @"uploadimage";
        
        // 上传数据时，request的requestType必须设置为上传类型， 当前只支持 FormData方式上传
        request.requestType = EFNRequestTypeFormDataUpload;
        
        // 有时候接口不需要传递其他参数时，此句可以不设置
        request.parameters = @{@"key1":@"value"};
        
        // 添加需要上传的数据， name为文件对应的参数名称
        [request addFormDataWithName:@"img1" fileData:[NSData data]];
        [request addFormDataWithName:@"img2" fileData:[NSData data]];
        [request addFormDataWithName:@"img3" fileData:[NSData data]];
        [request addFormDataWithName:@"pdf1" fileData:[NSData data]];
        [request addFormDataWithName:@"zip1" fileData:[NSData data]];
    }
                              progress:^(NSProgress * _Nullable progress) {
                                  EFNLog(@"progress:%@", progress);
                              }
                               success:^(EFNResponse * _Nullable response) {
                                   EFNLog(@"responseObject:%@",response.dataObject);
                               }
                               failure:^(EFNResponse * _Nullable response) {
                                   EFNLog(@"error:%@", response.message);
                               }];
}

- (void)testUpload
{
    [EFNetHelper.shareHelper request:^(EFNRequest * _Nonnull request) {
        request.url = @"http://api.baidu.com/file/upload";
        request.parameters = @{@"path":@"EFNetWorking/demo"};
        request.requestType = EFNRequestTypeFormDataUpload;
        
        UIImage *image = [UIImage imageNamed:@"efnetworking.png"];
    
        [request addFormDataWithName:@"file"
                            fileName:@"servername.png"
                            mimeType:@"image/png"
                            fileData:UIImagePNGRepresentation(image)];
    }
                            progress:^(NSProgress * _Nullable progress) {
                                EFNLog(@"progress:%@",progress.localizedDescription);
                            }
                             success:^(EFNResponse * _Nullable response) {
                                 EFNLog(@"response:%@",response.description);
                             }
                             failure:^(EFNResponse * _Nullable response) {
                                 EFNLog(@"response:%@",response.description);
                             }];
}

@end
