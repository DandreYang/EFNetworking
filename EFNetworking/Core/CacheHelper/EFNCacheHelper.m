//
//  EFNCacheHelper.m
//  EFNetworking
//
//  Created by Dandre on 2018/4/9.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import "EFNCacheHelper.h"
#import "NSString+EFNetworking.h"
#import "NSDictionary+EFNetworking.h"
#import "NSArray+EFNetworking.h"
#if __has_include(<YYCache/YYCache.h>)
#import <YYCache/YYCache.h>
#elif __has_include(<YYWebImage/YYCache.h>)
#import <YYWebImage/YYCache.h>
#else
#import "YYCache.h"
#endif

@interface EFNCacheHelper ()

@property (nonatomic, strong) YYCache *cache;

@end

@implementation EFNCacheHelper

#pragma mark - Life Cycle
+ (instancetype)shared
{
    static EFNCacheHelper * helper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[self alloc] init];
    });
    
    return helper;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 默认缓存储存在 Library/Cache/EFNetworking/目录下
        NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *path = [cacheFolder stringByAppendingPathComponent:@"EFNetworking"];
        
        self.cache = [[YYCache alloc] initWithPath:path];
    }
    return self;
}

- (void)saveResponse:(EFNResponse *)response forRequest:(EFNRequest * _Nonnull)request
{
    if (!response) {
        return;
    }
    
    if (response.error) {
        // 只缓存无错误的信息
        return;
    }
    
    NSString * key = [self keyForRequest:request];
    
    [self setObject:response.dataObject forKey:key];
    
    if (request.enableCache) {
        self.cache.diskCache.ageLimit = request.cacheTimeout;
    }else{
        self.cache.diskCache.ageLimit = 0;
    }
    
    [self setObject:response.dataObject forKey:key];
}

- (EFNResponse *)responseForRequest:(EFNRequest * _Nonnull)request
{
    id object = [self objectForKey:[self keyForRequest:request]];
    
    EFNResponse *response = [[EFNResponse alloc] initWithCacheObject:object];
    
    return response;
}

- (BOOL)containsObjectForRequest:(EFNRequest *)request
{
    return [self.cache containsObjectForKey:[self keyForRequest:request]];
}

- (NSInteger)totalCacheSize
{
    return self.cache.diskCache.totalCost;
}

#pragma mark - Remove Methods
- (void)removeObjectForRequest:(EFNRequest *)request
{
    [self.cache removeObjectForKey:[self keyForRequest:request]];
}

- (void)removeObjectForRequest:(EFNRequest *)request withBlock:(nullable void(^)(NSString *key))block
{
    [self.cache removeObjectForKey:[self keyForRequest:request] withBlock:block];
}

- (void)removeAllObjects
{
    [self.cache removeAllObjects];
}

- (void)removeAllObjectsWithBlock:(void(^)(void))block
{
    [self.cache removeAllObjectsWithBlock:block];
}

- (void)removeAllObjectsWithProgressBlock:(nullable void(^)(int removedCount, int totalCount))progress
                                 endBlock:(nullable void(^)(BOOL error))end
{
    [self.cache removeAllObjectsWithProgressBlock:progress endBlock:end];
}

#pragma mark - Private Setter & Getter
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key
{
    // 缓存时使用异步，不阻碍主线程
    [self.cache setObject:object forKey:key withBlock:^{
        EFNLog(@"缓存数据成功");
    }];
}

- (id<NSCoding>)objectForKey:(NSString *)key
{
    return [self.cache objectForKey:key];
}

- (NSString *)keyForRequest:(EFNRequest * _Nonnull)request {
    NSParameterAssert(request);
    NSParameterAssert(request.url);
    
    if (request == nil || request.url.length == 0) {
        return @"";
    }
    
    NSString *query = @"";
    if ([request.parameters isKindOfClass:[NSDictionary class]]) {
        query = [(NSDictionary *)request.parameters efn_toURLQuery];
    }else if ([request.parameters isKindOfClass:[NSArray class]]) {
        query = [(NSArray *)request.parameters efn_toJSONString];
    }
    
    NSString *key = [[request.url stringByAppendingString:query] efn_MD5_32_Encode];
    
    return key;
}

@end
