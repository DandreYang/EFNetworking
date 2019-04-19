//
//  NSArray+EFNetworking.m
//  EFNetworking
//
//  Created by Dandre on 2018/4/10.
//  Copyright © 2018年 Dandre.Vip All rights reserved.
//

#import "NSArray+EFNetworking.h"

@implementation NSArray (EFNetworking)

- (NSString *)efn_toJSONString
{
    NSError *error = nil;

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return jsonString;
}

@end
