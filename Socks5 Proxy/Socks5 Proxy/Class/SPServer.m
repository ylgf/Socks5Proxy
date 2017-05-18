//
//  SPServer.m
//  Socks5 Proxy
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "SPServer.h"
#import "SPConnect.h"
#import "GCDAsyncSocket.h"
#import "SPSocketUtil.h"
#import "SPConfigManager.h"

@interface SPServer()<GCDAsyncSocketDelegate>

@property (nonatomic, assign) uint16_t localPort;
@property (nonatomic, copy) NSString *remoteURL;
@property (nonatomic, assign) uint16_t remotePort;

@property (nonatomic, strong) NSMutableArray<SPConnect *> *connects;

@end

@implementation SPServer

+ (NSArray *)encrpyTypes {
    return @[@"aes_256_cfb", @"empty"];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _connects = [NSMutableArray array];
        _localPort = [SPConfigManager shared].localPort;
        _remoteURL = [SPConfigManager shared].remoteAddress;
        _remotePort = [SPConfigManager shared].remotePort;
        
        _localSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create("zkhCreator.proxy.queue.local", 0)];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:receiveStringNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)start {
    NSError *error = nil;

    BOOL isListenToLocalPort = [_localSocket acceptOnPort:_localPort error:&error];
    
    if (isListenToLocalPort) {
        DDLogVerbose(@"本地接口监听成功");
    } else {
        DDLogVerbose(@"本地接口监听成功");
    }
    
}

- (void)stop {
    for (SPConnect *connect in _connects) {
        [connect disconnect];
    }
}

- (void)sendStringToRemote:(NSString *)string {
    NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [self sendDataToRemote:data];
}

- (void)sendDataToRemote:(NSData *)data {
    // 创建一个connect，用于数据传输。
    SPConnect *conn = [[SPConnect alloc] initWithSocket:_localSocket];
    [_connects addObject:conn];
    [conn startConnectWithData:data];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"local:host:%@ port:%d", newSocket.localHost, newSocket.localPort);
    NSLog(@"remote:host:%@ port:%d", newSocket.connectedHost, newSocket.connectedPort);
    
    BOOL socketExist = NO;
    
    for (SPConnect *conn in _connects) {
        if ([conn checkSocket:newSocket]) {
            socketExist = YES;
            break;
        }
    }
    
    if (newSocket && !socketExist) {
        SPConnect *conn = [[SPConnect alloc] initWithSocket:newSocket];
        conn.tag = _connects.count;
        [_connects addObject:conn];
        [conn startConnect];
    }
}
//
//- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
//    
//    SPConnect *currentConnect;
//    for (SPConnect *connect in _connects) {
//        if (tag == connect.tag) {
//            currentConnect = connect;
//            break;
//        }
//    }
//    if (sock == currentConnect.inComeSocket) {
//        
//        [currentConnect.outGoSocket writeData:data withTimeout:-1 tag:SOCKS_OUTGOING_WRITE];
//    } else {
//        [_localSocket writeData:data withTimeout:-1 tag:SOCKS_INCOMING_WRITE];
//    }
//    
//    [_localSocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
//    [currentConnect.outGoSocket readDataWithTimeout:-1 tag:SOCKS_OUTGOING_READ];
//}

- (void)receiveNotification:(NSNotification *) notification {
    if (notification.name == receiveStringNotification) {
        NSDictionary *userInfo = notification.userInfo;
        SPConnect *conn = [userInfo objectForKey:@"connect"];
        NSData *data = [userInfo objectForKey:@"data"];
        NSLog(@"data: %@", data);
        
        [conn disconnect];
        [_connects removeObject:conn];
    }
}

@end
