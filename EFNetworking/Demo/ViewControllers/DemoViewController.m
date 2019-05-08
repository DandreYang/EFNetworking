//
//  DemoViewController.m
//  EFNetworking
//
//  Created by Dandre on 2018/3/20.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import "DemoViewController.h"
#import "EFNetHelper.h"
#import "DemoRequestModel.h"
#import "DemoResponseModel.h"
#import "DemoSignService.h"

@interface DemoViewController ()

@property (weak, nonatomic) IBOutlet UIProgressView *uploadProgressView;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;

@property (nonatomic, strong) NSNumber *uploadRequestID;
@property (nonatomic, strong) NSNumber *downloadRequestID;

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)requestBtnClicked:(id)sender {
//    [self request];
    [self modelRequest];
}

- (void)dealloc {
    [EFNetHelper.shareHelper cancelAllRequests];
}

/**
 普通请求示例
 */
- (void)request
{
    [EFNetHelper.shareHelper request:^(EFNRequest * _Nonnull request) {
        // 此处若不设置request.server，会自动取全局配置里的generalServer
        // 若设置了 request.server，则以request.server的值为准
        // request.server = @"http://api2.abc.com";
        request.api = @"testapi";
        
        // 默认的HTTPMethod是POST，如果不是POST，在这里需要做下设置，
        request.HTTPMethod = EFNHTTPMethodGET;
        
        // 设置请求参数，请求参数可以是字典，也可以是数组，根据API实际规则做设置即可
        request.parameters = @{@"key1":@"value2"};
        
        // 设置是否允许缓存数据
        request.enableCache = YES;
        // 设置缓存时间，默认为 1800 秒
        request.cacheTimeout = 60*60*60;
        
    } success:^(EFNResponse * _Nullable response) {
        EFNLog(@"%@", response);
    } failure:^(EFNResponse * _Nullable response) {
        EFNLog(@"%@", response);
    }];
}

/**
 使用请求模型请求示例
 */
- (void)modelRequest
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
    
    EFNLog(@"req:%@", req);
    
    [EFNetHelper.shareHelper request:req
                            reformer:^id<EFNResponseDataReformer> _Nullable{
                                DemoResponseModel *resModel = [[DemoResponseModel alloc] init];
                                return resModel;
                            }
                            progress:^(NSProgress * _Nullable progress) {
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

/**
 上传文件示例
 */
- (IBAction)uploadBtnClicked:(id)sender {
    self.uploadRequestID = [EFNetHelper.shareHelper request:^(EFNRequest * _Nonnull request) {
                                request.api = @"file/upload";
                                request.parameters = @{@"path":@"EFNetWorking/demo"};
                                request.requestType = EFNRequestTypeFormDataUpload;
        
                                UIImage *image = [UIImage imageNamed:@"EFNetworking-title"];
                                NSData *data = UIImagePNGRepresentation(image);

                                [request appendUploadDataWithFileData:data name:@"EFNetworking-title.png"];
                            }
                                                    progress:^(NSProgress * _Nonnull progress) {
                                                        float unitCount = 100.0f * progress.completedUnitCount/progress.totalUnitCount;
                                                        EFNLog(@"%@",[NSString stringWithFormat:@"已下载 %.2f%%",unitCount]);
                                                        self.uploadProgressView.progress = unitCount / 100;
                                                    }
                                                     success:^(EFNResponse * _Nonnull response) {
                                                         EFNLog(@"response:%@",response.description);
                                                     }
                                                     failure:^(EFNResponse * _Nonnull response) {
                                                         EFNLog(@"response:%@",response.description);
                                                     }];
}

- (IBAction)suspendUploadBtnClicked:(id)sender {
    [EFNetHelper.shareHelper suspendWithRequestID:self.uploadRequestID];
}

- (IBAction)resumeUploadBtnClicked:(id)sender {
    [EFNetHelper.shareHelper resumeWithRequestID:self.uploadRequestID];
}

/**
 下载文件示例
 */
- (IBAction)downloadBtnClicked:(id)sender {
    self.downloadProgressView.progress = 0;
    
    if (self.downloadRequestID) {
        [EFNetHelper.shareHelper cancelAllRequests];
        self.downloadRequestID = nil;
    }
    
    self.downloadRequestID = [EFNetHelper.shareHelper request:^(EFNRequest * _Nonnull request) {
                                // 这里如果直接设置了url,url的格式必须是带http://或https://的url全路径，如：http://www.abc.com
                                // 直接设置url后，server和api将失效，也就是url的优先级是高于 server+api方式的
//                                request.url = @"https://github.com/DandreYang/EFNetworking/archive/master.zip";
                                request.url = @"https://github.com/CocoaPods/Specs/archive/master.zip";
       
                                // 默认的requestType = EFNRequestTypeGeneral，如果是下载和上传请求，这里需要做下设置，否则可能会报错
                                request.requestType = EFNRequestTypeDownload;
       
                                // 设置下载文件的保存路径，针对单一下载请求，可以指定到一个明确的下载路径
                                // 如果这里没有做设置，会取全局配置的generalDownloadSavePath（文件夹），
                                // 如果全局配置也没有设置generalDownloadSavePath，则会默认保存在APP的"Documents/EFNetworking/Download/"目录下
                                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                NSString *documentsDirectory = paths.firstObject;

                                NSString *path = [documentsDirectory stringByAppendingPathComponent:@"/Demo/Download"];
                                request.downloadSavePath = path;
                                request.enableResumeDownload = YES;
                                request.parameters = @{};
                            }
                                                    progress:^(NSProgress * _Nonnull progress) {
                                                        // 需要注意的是，网络层内部已经做了处理，这里已经是在主线程了
                                                        float unitCount = 100.0f * progress.completedUnitCount/progress.totalUnitCount;
                                                        EFNLog(@"%@",[NSString stringWithFormat:@"已下载 %.2f%%",unitCount]);
                                                        self.downloadProgressView.progress = unitCount / 100;
                                                    }
                                                     success:^(EFNResponse * _Nonnull response) {
                                                         self.downloadRequestID = nil;
                                                         EFNLog(@"response:%@",response.description);
                                                     }
                                                     failure:^(EFNResponse * _Nonnull response) {
                                                         self.downloadRequestID = nil;
                                                         EFNLog(@"response:%@",response.description);
                                                     }];
}

- (IBAction)suspendDownloadBtnClicked:(id)sender {
    [EFNetHelper.shareHelper suspendWithRequestID:self.downloadRequestID];
}

- (IBAction)resumeDownloadBtnClicked:(id)sender {
    [EFNetHelper.shareHelper resumeWithRequestID:self.downloadRequestID];
}

@end
