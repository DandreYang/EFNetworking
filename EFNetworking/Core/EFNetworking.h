//
//  EFNetworking.h
//  EFNetworking
//
//  Created by Dandre on 2019/4/17.
//  Copyright © 2019 Dandre.Vip. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

          /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
         /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////                         /////////                         /////////         ///////////////       ///////////
       ///////////       ///////////////////////////       ///////////////////////////              //////////       ///////////
      ///////////       ///////////////////////////       ///////////////////////////       ///       ///////       ///////////
     ///////////                         /////////                         /////////       //////       ////       ///////////
    ///////////       ///////////////////////////       ///////////////////////////       /////////       /       ///////////
   ///////////       ///////////////////////////       ///////////////////////////       /////////////           ///////////
  ///////////                         /////////       ///////////////////////////       ///////////////         ///////////
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

#if __has_include(<EFNetworking/EFNetworking.h>)

FOUNDATION_EXPORT double EFNetworkingVersionNumber;
FOUNDATION_EXPORT const unsigned char EFNetworkingVersionString[];

#import <EFNetworking/EFNHeader.h>
#import <EFNetworking/EFNRequest.h>
#import <EFNetworking/EFNResponse.h>
#import <EFNetworking/EFNCacheHelper.h>
#import <EFNetworking/EFNetProxy.h>
#import <EFNetworking/NSString+EFNetworking.h>
#import <EFNetworking/NSArray+EFNetworking.h>
#import <EFNetworking/NSDictionary+EFNetworking.h>
#import <EFNetworking/EFNetHelper.h>

#else

#import "EFNHeader.h"
#import "EFNRequest.h"
#import "EFNResponse.h"
#import "EFNCacheHelper.h"
#import "EFNetProxy.h"
#import "NSString+EFNetworking.h"
#import "NSArray+EFNetworking.h"
#import "NSDictionary+EFNetworking.h"
#import "EFNetHelper.h"

#endif /* __has_include */
#endif /* _EFNetworking_ */
