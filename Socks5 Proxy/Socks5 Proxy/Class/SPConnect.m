//
//  SPConnect.m
//  Socks5 Proxy
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "SPConnect.h"
#import "SPSocketUtil.h"
#import "NSData+SPAES.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "NSString+convertData.h"

@interface SPRemoteConfig()

@property (nonatomic, copy) NSString *remoteAddress;
@property (nonatomic, assign) NSInteger remotePort;

@end

@implementation SPRemoteConfig

- (instancetype)initWithAddress:(NSString *)address port:(NSInteger)port {
    self = [super init];
    if (self) {
        _remoteAddress = address;
        _remotePort = port;
    }
    return self;
}

@end

@interface SPConnect()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *inComeSocket;
@property (nonatomic, strong) GCDAsyncSocket *outGoSocket;
@property (nonatomic, strong) SPRemoteConfig *remoteConfig;
@property (nonatomic, copy) NSData *currentData;

@end

@implementation SPConnect

- (instancetype)initWithSocket:(GCDAsyncSocket*) socket remoteConfig:(SPRemoteConfig *)config {
    if (self = [super init]) {
        _inComeSocket = socket;
        _outGoSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create("com.zkhCreator.socket.queue", 0)];
        _remoteConfig = config;
    }
    return self;
}

- (void)disconnect {
    [_outGoSocket disconnectAfterReadingAndWriting];
}

- (void)startConnectWithData:(NSData *)data {
    DDLogVerbose(@"start connect");
    // 储存数据准备连接到远端的服务端。
    _currentData = data;
    NSError *error;
    BOOL isConnect = [_outGoSocket connectToHost:_remoteConfig.remoteAddress onPort:_remoteConfig.remotePort error:&error];
    if (isConnect) {
        DDLogVerbose(@"connect success");
        [self socketOpenSOCKS5];
    } else {
        DDLogVerbose(@"connect failed");
    }
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    switch (tag) {
        case SOCKS_OPEN:
            [self socket:sock readResponseSocketOn:data];
            break;
            
        default:
            break;
    }
}


- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    switch (tag) {
        case SOCKS_OPEN:
            [self socketWithResponseSocketOn:sock];
            break;
            
        default:
            break;
    }
}

/*
 +----+----------+----------+
 |VER | NMETHODS | METHODS  |
 +----+----------+----------+
 | 1  |    1     | 1 to 255 |
 +----+----------+----------+ */
// 开始 socket 请求
- (void)socketOpenSOCKS5 {
    NSUInteger requestLength = 3;
    uint8_t *checkVersionData = malloc(requestLength * sizeof(uint8_t));
    // 组装数据
    checkVersionData[0] = 5;    // SOCKS VERSION
    checkVersionData[1] = 1;    // Method Length
    checkVersionData[2] = 0x02; // username Check
    
    NSData *requestData = [NSData dataWithBytesNoCopy:checkVersionData length:requestLength];
    DDLogVerbose(@"start connect: Check SOCKS Version");
    [_outGoSocket writeData:requestData withTimeout:-1 tag:SOCKS_OPEN];
}

#pragma mark - After Read Method

//      +-----+--------+
// NAME | VER | METHOD |
//      +-----+--------+
// SIZE |  1  |   1    |
//      +-----+--------+
- (void)socket:(GCDAsyncSocket *)socket readResponseSocketOn:(NSData *)data {
    if (data.length >= 2) {
        uint8_t *bytes = (uint8_t *)data.bytes;
        uint8_t methodByte = bytes[1];  // 检验对应的验证格式 0x00 为 不需要验证， 0x02 为进行身份验证。
        
        DDLogVerbose(@"start connect: Check SOCKS Version Successed.Outgo URL: %@, PORT:%d", socket.connectedUrl, socket.connectedPort);
        
        if (methodByte == 0x02) {
            DDLogVerbose(@"start connect: Start Check Auth");
            [_outGoSocket writeData:[self authData:@"admin" password:@"admin888"]  withTimeout:-1 tag:SOCKS_CONNECT_AUTH_INIT];
        } else {
            
        }
    }
}

- (void)socket:(GCDAsyncSocket *)socket writeConnectData:(NSData *)data {
    
}


#pragma mark - After Write Method
// 发送 协商协议类型之后等待获得数据
- (void)socketWithResponseSocketOn:(GCDAsyncSocket *)socket {
    [socket readDataWithTimeout:-1 tag:SOCKS_OPEN];
}

#pragma mark - MakeUp Data 
- (NSData *)authData:(NSString *)username password:(NSString *)password {
    NSMutableData *data = [NSMutableData data];
    uint8_t version = 0x05; // 版本号
    
    NSData *usernameData = [username convertData];
    uint8_t usernameLength = usernameData.length;
    
    NSData *passwordData = [password convertData];
    uint8_t passwordLength = passwordData.length;
    
    
    [data appendBytes:&version length:1];    //增加版本号
    
    [data appendBytes:&usernameLength length:1]; //用户名长度
    [data appendData:usernameData];
    
    [data appendBytes:&passwordLength length:1]; //密码长度
    [data appendData:passwordData];
    
    return data;
}

@end
