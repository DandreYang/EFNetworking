//
//  DemoRequestModel.h
//  EFNetworking
//
//  Created by Dandre on 2019/4/18.
//  Copyright © 2019 Exceptional Financial Services Ltd. All rights reserved.
//

#import "DemoRequestModelReformer.h"

NS_ASSUME_NONNULL_BEGIN

@interface DemoRequestModel : DemoRequestModelReformer

@property (nonatomic, copy) NSString *key1;
@property (nonatomic, copy) NSString *key2;
/** ...... */
@property (nonatomic, copy) NSString *keyn;

@end

NS_ASSUME_NONNULL_END
