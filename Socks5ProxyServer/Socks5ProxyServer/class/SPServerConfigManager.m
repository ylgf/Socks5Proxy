//
//  SPServerConfigManager.m
//  Socks5ProxyServer
//
//  Created by zkhCreator on 19/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "SPServerConfigManager.h"

@implementation SPServerConfigManager

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static SPServerConfigManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[SPServerConfigManager alloc] init];
    });
    return manager;
}

@end
