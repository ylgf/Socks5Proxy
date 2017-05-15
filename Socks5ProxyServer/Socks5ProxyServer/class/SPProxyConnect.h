//
//  SPProxyConnect.h
//  Socks5ProxyServer
//
//  Created by zkhCreator on 15/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"


@class GCDAsyncSocket;
@interface SPProxyConnect : NSObject<GCDAsyncSocketDelegate>

- (instancetype)initWithSocket:(GCDAsyncSocket*)socket listenPort:(NSInteger)listenPort;
- (void)connect;
- (void)stop;

@end
