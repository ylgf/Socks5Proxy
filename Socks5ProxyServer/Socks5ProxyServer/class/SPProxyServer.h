//
//  SPProxyServer.h
//  Socks5ProxyServer
//
//  Created by zkhCreator on 15/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "SPProxyConnect.h"

@interface SPProxyServer : NSObject


- (instancetype)initWithListenPort:(NSInteger) port;
+ (NSArray *)encrpyTypes;
- (void)start;

@end
