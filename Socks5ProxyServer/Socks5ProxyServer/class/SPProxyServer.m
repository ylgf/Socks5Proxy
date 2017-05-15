//
//  SPProxyServer.m
//  Socks5ProxyServer
//
//  Created by zkhCreator on 15/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "SPProxyServer.h"

@interface SPProxyServer()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *listenSocket;
@property (nonatomic, strong) NSMutableArray<SPProxyConnect *> *conns;
@property (nonatomic, assign) NSInteger listenPort;

@end

@implementation SPProxyServer

- (instancetype)initWithListenPort:(NSInteger) port {

    if (port < 4000) {
        return nil;
    }
    
    if (self = [super init]) {
        _listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create("com.zkhCreator.proxyServer.receive", 0)];
        _conns = [NSMutableArray array];
        _listenPort = port;
    }
    
    return self;
}

- (void)start {
    NSError *error;
    BOOL isListen = [_listenSocket acceptOnPort:_listenPort error:&error];
    
    if (isListen) {
        NSLog(@"监听端口成功");
    } else {
        NSLog(@"监听端口失败");
    }
}

- (void)stop {
    for (SPProxyConnect *conn in _conns) {
        [conn stop];
    }
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    if (newSocket) {
        SPProxyConnect *conn = [[SPProxyConnect alloc] initWithSocket:newSocket listenPort:(NSInteger)_listenPort];
        [_conns addObject:conn];
        [newSocket setDelegate:conn];
    }
    
}



@end
