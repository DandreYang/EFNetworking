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

- (void)testStreamUploadRequest
{
    [[EFNetHelper shareHelper] request:^(EFNRequest * _Nonnull request) {
        
        // 设置上传服务地址
        request.server = @"http://api.baidu.com";
        request.api = @"uploadimage";
        
        // 上传数据时，request的requestType必须设置为上传类型
        request.requestType = EFNRequestTypeStreamUpload;
        
        // 有时候接口不需要传递其他参数时，此句可以不设置
        request.parameters = @{@"key1":@"value"};
        
        // 添加需要上传的数据， name为文件对应的参数名称
        [request appendUploadDataWithFileData:[NSData data]];
        [request appendUploadDataWithFileData:[NSData data]];
        [request appendUploadDataWithFileData:[NSData data]];
        [request appendUploadDataWithFileData:[NSData data]];
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

- (void)testFormDataUploadRequest
{
    [[EFNetHelper shareHelper] request:^(EFNRequest * _Nonnull request) {
        
        // 设置上传服务地址
        request.server = @"http://api.baidu.com";
        request.api = @"uploadimage";
        
        // 上传数据时，request的requestType必须设置为上传类型
        request.requestType = EFNRequestTypeFormDataUpload;
        
        // 有时候接口不需要传递其他参数时，此句可以不设置
        request.parameters = @{@"key1":@"value"};
        
        // 添加需要上传的数据， name为文件对应的参数名称
        [request appendUploadDataWithFileData:[NSData data] name:@"img1"];
        [request appendUploadDataWithFileData:[NSData data] name:@"img2"];
        [request appendUploadDataWithFileData:[NSData data] name:@"pdf1"];
        [request appendUploadDataWithFileData:[NSData data] name:@"zip1"];
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

- (void)testUpload
{
    [EFNetHelper.shareHelper request:^(EFNRequest * _Nonnull request) {
        request.url = @"http://api.baidu.com/file/upload";
        request.parameters = @{@"path":@"EFNetWorking/demo"};
        request.requestType = EFNRequestTypeFormDataUpload;
        
        UIImage *image = [UIImage imageNamed:@"efnetworking.png"];
    
        [request appendUploadDataWithFileData:UIImagePNGRepresentation(image)
                                         name:@"file"
                                     fileName:@"serverfilename.png"
                                     mimeType:@"image/png"];
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
