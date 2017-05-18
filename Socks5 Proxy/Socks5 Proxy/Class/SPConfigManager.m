//
//  SPConfigManager.m
//  Socks5 Proxy
//
//  Created by zkhCreator on 18/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "SPConfigManager.h"

@implementation SPConfigManager

+ (instancetype)shared {
    
    static dispatch_once_t onceToken;
    static SPConfigManager *sharedManager;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [[SPConfigManager alloc] init];
    });
    
    return sharedManager;
}

@end
