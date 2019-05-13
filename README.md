<p align="center" >
  <img src="./EFNetworking/Demo/Sources/EFNetworking-title.png" height="200" alt="EFNetworking" title="EFNetworking"/>
</p>

[![Build Status](https://travis-ci.org/DandreYang/EFNetworking.svg?branch=master)](https://travis-ci.org/DandreYang/EFNetworking)
[![Version](https://img.shields.io/cocoapods/v/EFNetworking.svg?style=flat)](http://cocoapods.org/pods/EFNetworking)
[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/DandreYang/EFNetworking/master/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/EFNetworking.svg?style=flat)](http://cocoapods.org/pods/EFNetworking)
## 
iOS网络层组件，支持POST/GET/PUT/DELETE等网络请求和上传下载及断点续传功能，自带网络缓存处理机制、灵活设置接口签名、自定义HEADER和公共参数等功能

## CocoaPods
```ruby
pod 'EFNetworking'
```

## Architecture
### NetHepler
- `EFNetHelper`：网络请求管理类

### Components
- `EFNRequest`：封装URL请求相关请求参数
- `EFNResponse`：封装URL请求的相关响应数据
- `EFNCacheHelper`：网络层缓存管理器
- `EFNetProxy`：网络请求处理类（代理网关）

### Category
- `NSString+EFNetworking`
- `NSArray+EFNetworking`
- `NSDictionary+EFNetworking`

### Others
- `EFNHeader`：相关的公共宏、协议和枚举在这里定义
    - `EFNGeneralConfigDelegate`
    - `EFNSignService`
    - `EFNRequestModelReformer`
    - `EFNResponseDataReformer`

## Dependencies
 - ### AFNetworking
       
       - 3.0版本及以上
       - 网络请求等操作依赖此库
       - 如果项目中的基础网络库不是`AFNetworking`，可以通过重写`EFNetProxy`类中的相关方法实现
       - 重写`EFNetProxy`类时，需要重新定义宏 `#define _EFN_USE_AFNETWORKING_ 0`,其中 0代表不使用AFNetworking，1代表使用AFNetworking
 
 - ### YYCache
 
       - 1.0版本及以上
       - 网络层缓存处理依赖此库

## Usage example
### 全局配置
```objc

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
    // 设置全局支持请求的数据类型
    config.generalRequestSerializerType = EFNRequestSerializerTypeJSON;
    // 设置全局支持响应的数据类型
    config.generalResponseSerializerType = EFNResponseSerializerTypeJSON;
    
    // 这里设置的下载文件保存路径是对全局有效的，所以建议设置的路径是指定到文件夹而不是文件，否则后下载的文件会将之前下载的文件进行覆盖
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"/General/Download"];
    config.generalDownloadSavePath = path;
}];

```

### 普通GET/POST/PUT/DELETE等请求
```objc
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
    NSLog(@"%@", response);
} failure:^(EFNResponse * _Nullable response) {
    NSLog(@"%@", response);
}];
```

### 使用模型请求示例
```objc

// 实例化请求模型
DemoRequestModel *req = [[DemoRequestModel alloc] init];

req.api = @"helloworld";
req.key1 = @"value1";
req.key2 = @"value2";
req.keyn = @"valuen";

NSLog(@"req:%@", req);

[EFNetHelper.shareHelper request:req
                        reformer:^id<EFNResponseDataReformer> _Nullable{
                            DemoResponseModel *resModel = [[DemoResponseModel alloc] init];
                            return resModel;
                        }
                        progress:^(NSProgress * _Nullable progress) {
                            NSLog(@"progress:%@",progress.localizedDescription);
                        }
                        response:^(DemoResponseModel * reformData, EFNResponse * _Nonnull response) {
                            if (reformData.isSuccess) {
                                NSLog(@"请求成功，reformData:%@", reformData);
                            }else{
                                NSLog(@"请求失败，error：%@", response.error.localizedDescription);
                            }
                        }];
```

### 上传文件示例
```objc

[EFNetHelper.shareHelper request:^(EFNRequest * _Nonnull request) {
    request.api = @"file/upload";
    request.parameters = @{@"path":@"EFNetWorking/demo"};
    request.requestType = EFNRequestTypeFormDataUpload;
   
    UIImage *image = [UIImage imageNamed:@"image1.png"];
    NSData *imgData = UIImagePNGRepresentation(image);
    [request appendUploadDataWithFileData:imgData name:@"img1"];
}
                        progress:^(NSProgress * _Nullable progress) {
                            NSLog(@"progress:%@",progress.localizedDescription);
                        }
                         success:^(EFNResponse * _Nullable response) {
                             NSLog(@"response:%@",response.description);
                         }
                         failure:^(EFNResponse * _Nullable response) {
                             NSLog(@"response:%@",response.description);
                         }];

```

### 下载文件示例
```objc

[EFNetHelper.shareHelper request:^(EFNRequest * _Nonnull request) {
    // 这里如果直接设置了url,url的格式必须是带http://或https://的url全路径，如：http://www.abc.com
    // 直接设置url后，server和api将失效，也就是url的优先级是高于 server+api方式的
    request.url = @"https://github.com/DandreYang/EFNetworking/archive/master.zip";
    
    // 默认的requestType = EFNRequestTypeGeneral，如果是下载和上传请求，这里需要做下设置，否则可能会报错
    request.requestType = EFNRequestTypeDownload;
    
    // 设置是否支持断点续传，默认为支持
    request.enableResumeDownload = YES;
    
    // 设置下载文件的保存路径，针对单一下载请求，可以指定到一个明确的下载路径，可以是文件夹或文件路径
    // 如果这里没有做设置，会取全局配置的generalDownloadSavePath（文件夹），
    // 如果全局配置也没有设置generalDownloadSavePath，则会默认保存在APP的"Documents/EFNetworking/Download/"目录下
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;

    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"/Demo/Download"];
    request.downloadSavePath = path;
}
                        progress:^(NSProgress * _Nullable progress) {
                            // 需要注意的是，网络层内部已经做了处理，这里已经是在主线程了
                            float unitCount = 1.0 * progress.completedUnitCount/progress.totalUnitCount;
                            NSLog(@"%@",[NSString stringWithFormat:@"已下载 %.0f%%",unitCount*100]);
                        }
                         success:^(EFNResponse * _Nullable response) {
                             NSLog(@"response:%@",response.description);
                         }
                         failure:^(EFNResponse * _Nullable response) {
                             NSLog(@"response:%@",response.description);
                         }];

```

## License

EFNetworking is released under the MIT license. See [LICENSE](./LICENSE) for details.
