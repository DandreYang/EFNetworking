//
//  EFNetworkingDownloadTests.m
//  EFNetworkingTests
//
//  Created by Dandre on 2018/3/29.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EFNetworking.h"

@interface EFNetworkingDownloadTests : XCTestCase

@end

@implementation EFNetworkingDownloadTests

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
    [EFNetHelper.shareHelper request:^(EFNRequest * _Nonnull request) {
        // 这里如果直接设置了url,url的格式必须是带http://或https://的url全路径，如：http://www.abc.com
        // 直接设置url后，server和api将失效，也就是url的优先级是高于 server+api方式的
        request.url = @"https://github.com/DandreYang/EFNetworking/archive/master.zip";
        
        // 默认的requestType = EFNRequestTypeGeneral，如果是下载和上传请求，这里需要做下设置，否则可能会报错
        request.requestType = EFNRequestTypeDownload;
        
        // 设置下载文件的保存路径，针对单一下载请求，可以指定到一个明确的下载路径
        // 如果这里没有做设置，会取全局配置的generalDownloadSavePath（文件夹），
        // 如果全局配置也没有设置generalDownloadSavePath，则会默认保存在APP的"Documents/EFNetworking/Download/"目录下
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = paths.firstObject;
        
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"/Demo/Download"];
        request.downloadSavePath = path;
    }
                            progress:^(NSProgress * _Nonnull progress) {
                                // 需要注意的是，网络层内部已经做了处理，这里已经是在主线程了
                                float unitCount = progress.completedUnitCount/progress.totalUnitCount;
                                EFNLog(@"%@",[NSString stringWithFormat:@"已下载 %.0f%%",unitCount*100]);
                            }
                             success:^(EFNResponse * _Nonnull response) {
                                 EFNLog(@"response:%@",response.description);
                             }
                             failure:^(EFNResponse * _Nonnull response) {
                                 EFNLog(@"response:%@",response.description);
                             }];
}

@end
