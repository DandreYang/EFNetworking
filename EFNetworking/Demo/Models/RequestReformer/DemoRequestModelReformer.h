//
//  RequestModelReformer.h
//  EFNetworking
//
//  Created by Dandre on 2019/4/18.
//  Copyright © 2019 Exceptional Financial Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EFNHeader.h"
NS_ASSUME_NONNULL_BEGIN

@interface DemoRequestModelReformer : NSObject <EFNRequestModelReformer>

/**
 将对象转换成dictionary的方法
 */
- (NSDictionary *_Nonnull)toDictionary;

@end

NS_ASSUME_NONNULL_END
