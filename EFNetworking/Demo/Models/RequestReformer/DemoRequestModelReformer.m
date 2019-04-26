//
//  RequestModelReformer.m
//  EFNetworking
//
//  Created by Dandre on 2019/4/18.
//  Copyright © 2019 Exceptional Financial Services Ltd. All rights reserved.
//

#import "DemoRequestModelReformer.h"
#import "NSDictionary+EFNetworking.h"
#import "DemoSignService.h"

@implementation DemoRequestModelReformer

@synthesize server;
@synthesize api;
@synthesize HTTPMethod;
@synthesize requestType;
@synthesize signService;
@synthesize formDatas;

- (NSDictionary *)toDictionary {
    return [NSDictionary efn_dictionaryWithObject:self];
}

- (NSString *)description {
    NSDictionary *dict = [self toDictionary];
    NSString *des = [NSString stringWithFormat:@"<%@: %p> => %@", [self class], self, dict];
    return des.copy;
}

@end
