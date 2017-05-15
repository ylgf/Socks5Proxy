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

@interface SPServer()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) NSString *address;
@property (nonatomic, assign) int port;
@property (nonatomic, strong) NSMutableArray<SPConnect *> *connects;
@property (nonatomic, copy) NSString *encryptionType;
@property (nonatomic, strong) GCDAsyncSocket *localSocket;

@end

@implementation SPServer

+ (NSArray *)encrpyTypes {
    return @[@"aes_256_cfb", @"aes_256_ctr"];
}

- (instancetype)initWithHost:(NSString *)address port:(int)port encryptionType:(NSString *)type {
    self = [super init];
    if (self) {
        _address = address;
        _port = port;
        _connects = [NSMutableArray array];
        _encryptionType = type;
        
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
    BOOL isListenToLocalPort = [_localSocket acceptOnPort:_port error:&error];
    
    if (isListenToLocalPort) {
        NSLog(@"本地接口监听成功");
    } else {
        NSLog(@"本地接口监听失败");
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
    // 设置服务端的相关参数
    SPRemoteConfig *config = [[SPRemoteConfig alloc] initWithAddress:_address port:55556];
    // 创建一个connect，用于数据传输。
    SPConnect *conn = [[SPConnect alloc] initWithSocket:_localSocket remoteConfig:config];
    [_connects addObject:conn];
    [conn startConnectWithData:data];
}

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
