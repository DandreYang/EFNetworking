//
//  NSDictionary+EFNetworking.m
//  EFNetworking
//
//  Created by Dandre on 2018/4/4.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import "NSDictionary+EFNetworking.h"
#import <objc/runtime.h>

@implementation NSDictionary (EFNetworking)

- (NSString *)efn_toURLQuery
{
    __block NSMutableString *paramString = [NSMutableString string];
    __block NSArray * allKeys = self.allKeys;
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSInteger i = [allKeys indexOfObject:key];
        if (i == 0) {
            [paramString appendFormat:@"?%@=%@", key, obj];
        } else {
            [paramString appendFormat:@"&%@=%@", key, obj];
        }
    }];
    
    return paramString;
}

- (NSString *)efn_toJSONString
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:NULL];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


+ (NSDictionary *)efn_dictionaryWithObject:(NSObject *)object
{
    if (object == nil) {
        return @{};
    }

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    // 获取类名/根据类名获取类对象
    NSString *className = NSStringFromClass([object class]);
    id classObject = objc_getClass([className UTF8String]);
    
    // 获取所有属性
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(classObject, &count);
    
    // 遍历所有属性
    for (int i = 0; i < count; i++) {
        // 取得属性
        objc_property_t property = properties[i];
        // 取得属性名
        NSString *propertyName = [[NSString alloc] initWithCString:property_getName(property)
                                                          encoding:NSUTF8StringEncoding];
        // 取得属性值
        id propertyValue = [object valueForKey:propertyName]?:[NSNull null];
        
        [dict setObject:propertyValue forKey:propertyName];
    }
    
    free(properties);
    
    return [dict copy];
}

@end

@implementation NSMutableDictionary (EFNetworking)

- (void)efn_removeObjectsForProtocol:(Protocol *)protocol
{
    unsigned int count;
    
    objc_property_t *properties = protocol_copyPropertyList(protocol, &count);
    NSArray *allKeys = [self allKeys];
    for (int i = 0; i < count; i++) {
        // objc_property_t 属性类型
        objc_property_t property = properties[i];
        // 获取属性的名称 C语言字符串
        const char *cName = property_getName(property);
        // 转换为Objective C 字符串
        NSString *key = [NSString stringWithCString:cName encoding:NSUTF8StringEncoding];
        
        if ([allKeys containsObject:key]) {
            [self removeObjectForKey:key];
        }
    }
}

@end
