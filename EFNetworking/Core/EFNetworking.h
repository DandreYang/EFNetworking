//
//  EFNetworking.h
//  EFNetworking
//
//  Created by Dandre on 2019/4/17.
//  Copyright © 2019 Exceptional Financial Services Ltd. All rights reserved.
//

/**
 * 项目地址：https://github.com/DandreYang/EFNetworking.git
 * EFNetworking 依赖以下开源类库：
 *
 * - AFNetworking
 *      - 3.0版本及以上
 *      - 网络请求等操作依赖此库
 *      - 如果项目中的基础网络库不是`AFNetworking`，可以通过重写`EFNetProxy`类中的相关方法实现
 *      - 重写`EFNetProxy`类时，需要重新定义宏 `#define _EFN_USE_AFNETWORKING_ 0`,其中 0代表不使用AFNetworking，1代表使用AFNetworking
 *
 * - YYCache
 *      - 1.0版本及以上
 *      - 网络层缓存处理依赖此库
 */

#ifndef _EFNETWORKING_
#define _EFNETWORKING_

#import "EFNHeader.h"
#import "EFNRequest.h"
#import "EFNResponse.h"
#import "EFNCacheHelper.h"
#import "EFNetProxy.h"
#import "NSString+EFNetworking.h"
#import "NSArray+EFNetworking.h"
#import "NSDictionary+EFNetworking.h"
#import "EFNetHelper.h"

#endif /* _EFNetworking_ */
