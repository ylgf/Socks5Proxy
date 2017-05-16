//
//  SPProxyConnect.h
//  Socks5ProxyServer
//
//  Created by zkhCreator on 15/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@protocol SPProxyConnectDelegate <NSObject>

- (void)socket:(GCDAsyncSocket *)socket didWriteDataLength:(NSUInteger)datalength;
- (void)socket:(GCDAsyncSocket *)socket didReadDataLength:(NSUInteger)datalength;

@end

@class GCDAsyncSocket;

@interface SPProxyConnect : NSObject<GCDAsyncSocketDelegate>

@property (nonatomic, weak) id<SPProxyConnectDelegate> delegate;

- (instancetype)initWithSocket:(GCDAsyncSocket*)socket listenPort:(NSInteger)listenPort;
- (void)connect;
- (void)stop;

@end
