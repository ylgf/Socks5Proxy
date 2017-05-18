//
//  SPServerConfigManager.h
//  Socks5ProxyServer
//
//  Created by zkhCreator on 19/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPServerConfigManager : NSObject

@property (nonatomic, assign) NSString *encryption;

+ (instancetype)shared;

@end
