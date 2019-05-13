//
//  AppDelegate.m
//  EFNetworking
//
//  Created by Dandre on 2018/3/20.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import "AppDelegate.h"
#import "EFNetworking.h"
#import "DemoSignService.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    /**
     *  在APP启动的时候配置全局设置
     */
    [self configNetHelper];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Config EFN
- (void)configNetHelper {
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
}

@end
