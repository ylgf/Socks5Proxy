//
//  SPProxyConnect.m
//  Socks5ProxyServer
//
//  Created by zkhCreator on 15/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "SPProxyConnect.h"
#import "GCDAsyncSocket.h"

@interface SPProxyConnect()
@property (nonatomic, strong) GCDAsyncSocket *remoteSocket;
@property (nonatomic, assign) NSInteger listenPort;

@end

@implementation SPProxyConnect

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket listenPort:(NSInteger)listenPort{
    if (!socket) {
        return nil;
    }
    
    if (self = [super init]) {
        _remoteSocket = socket;
        _listenPort = listenPort;
    }
    
    return self;
}

- (void)connect {
    [_remoteSocket readDataWithTimeout:-1 tag:0];
    
}

- (void)stop {
    [_remoteSocket disconnectAfterReadingAndWriting];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"socketURL: %@ socketPort: %hu data:%@", sock.connectedHost, sock.connectedPort, data);
    NSString *response = @"helloworld";
    [sock writeData:[response dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
}

@end
