//
//  SPConfigManager.h
//  Socks5 Proxy
//
//  Created by zkhCreator on 18/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPConfigManager : NSObject

@property (nonatomic, copy) NSString *localAddress;
@property (nonatomic, assign) uint16_t localPort;

@property (nonatomic, copy) NSString *remoteAddress;
@property (nonatomic, assign) uint16_t remotePort;

@property (nonatomic, copy) NSString *encrypt;

+ (instancetype)shared;

@end
