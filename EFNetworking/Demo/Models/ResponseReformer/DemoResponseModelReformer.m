//
//  DemoResponseModelReformer.m
//  EFNetworking
//
//  Created by Dandre on 2019/4/18.
//  Copyright © 2019 Exceptional Financial Services Ltd. All rights reserved.
//

#import "DemoResponseModelReformer.h"
#import "NSDictionary+EFNetworking.h"
@implementation DemoResponseModelReformer

@synthesize isSuccess;

- (id)reformData:(id<NSObject,NSCopying>)rawData {
    // rawData为接口返回的原始数据，一般为JSON，网络层默认会自动转换为字典
    
    // 这里只做返回的数据为字典的示例
    if ([rawData isKindOfClass:[NSDictionary class]]) {
        NSDictionary *rawDict = (NSDictionary *)rawData;
        
        [self setValuesForKeysWithDictionary:rawDict];
    }
    
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"key %@ is missed!", key);
}

- (NSString *)description {
    NSDictionary *dict = [NSDictionary efn_dictionaryWithObject:self];
    NSString *des = [NSString stringWithFormat:@"%p\n%@", self, dict];
    return des.copy;
}

@end
