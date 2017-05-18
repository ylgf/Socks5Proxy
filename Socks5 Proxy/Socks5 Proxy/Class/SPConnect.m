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

#import <arpa/inet.h>

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
@property (nonatomic, strong) NSString *requestURL;
@property (nonatomic, assign) uint16_t requestPort;

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

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket {
    if (self = [super init]) {
        _inComeSocket = socket;
        _outGoSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create("com.zkhCreator.socket.queue", 0)];
    }
    
    return self;
}

- (void)disconnect {
    [_outGoSocket disconnectAfterReadingAndWriting];
}

// 点击发送按钮
- (void)startConnectWithData:(NSData *)data {
    DDLogVerbose(@"click Send Button start connect");
    // 储存数据准备连接到远端的服务端。
    _currentData = data;
    NSError *error;
    BOOL isConnect = [_outGoSocket connectToHost:_remoteConfig.remoteAddress onPort:_remoteConfig.remotePort error:&error];
    if (isConnect) {
        DDLogVerbose(@"start connect: Connect To Remote Server Succeed");
        [self socketOpenSOCKS5];
    } else {
        DDLogVerbose(@"start connect: Connect To Remote Server Failed");
    }
}

- (void)startConnect {
    DDLogVerbose(@"start proxy");
    
    [_inComeSocket readDataWithTimeout:-1 tag:SOCKS_OPEN];
    
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    switch (tag) {
        case SOCKS_OPEN:
            NSLog(@"%@", data);
            [self socket:sock readResponseSocketOn:data];
            break;
        case SOCKS_CONNECT_AUTH_INIT:
            [self socket:sock checkConnectInitWithData:data];
            break;
        case SOCKS_CONNECT_REPLY:
            [self socket:sock startTransFormData:data];
            break;
        case SOCKS_INCOMING_READ:
        case SOCKS_OUTGOING_READ:
            [self socket:sock transFormingData:data];
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
        case SOCKS_CONNECT_INIT:
            [self socketWithConnectInit:sock];
            break;
            
        case SOCKS_OUTGOING_WRITE:
        case SOCKS_INCOMING_WRITE:
            [self socketResponseSocket:sock];
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
            [self socket:socket checkConnectInitWithData:data];
        }
    }
}

- (void)socket:(GCDAsyncSocket *)socket checkConnectInitWithData:(NSData *)data {
    uint8_t *statusBytes = (uint8_t *)data.bytes;
    uint8_t status = statusBytes[1];
    
    if (status == 0x00) {
        [self socketStartConnectInit];
    } else {
        DDLogVerbose(@"Start Connect: Auth Failed");
        [_outGoSocket disconnectAfterReading];
        DDLogVerbose(@"Start Connect: Disconnect After Reading");
    }
}

//      +-----+-----+-----+------+------+------+
// NAME | VER | CMD | RSV | ATYP | ADDR | PORT |
//      +-----+-----+-----+------+------+------+
// SIZE |  1  |  1  |  1  |  1   | var  |  2   |
//      +-----+-----+-----+------+------+------+
//
// Note: Size is in bytes
//
// Version      = 5 (for SOCKS5)
// Command      = 1 (for Connect)
// Reserved     = 0
// Address Type = 3 (1=IPv4, 3=DomainName 4=IPv6)
// Address      = P:D (P=LengthOfDomain D=DomainWithoutNullTermination)
// Port         = 0
- (void)socketStartConnectInit {
    DDLogVerbose(@"start Connect: Auth Success");
    NSMutableData *data = [NSMutableData data];
    
    SPIPAddressType type = [self checkAddressType:_requestURL];
    
    NSUInteger codeBeforeAddressLength = 3;
    uint8_t *codeBeforeAddress = malloc(codeBeforeAddressLength * sizeof(uint8_t));
    codeBeforeAddress[0] = 0x05;    // SOCKS Version
    codeBeforeAddress[1] = 0x01;    // for Connect
    codeBeforeAddress[2] = 0x00;    // Reserved
    
    [data appendBytes:&codeBeforeAddress length:codeBeforeAddressLength];
    
    switch (type) {
        case SPIPv4Address:
            [data appendData:[self createIPv4Address]];
            break;
        case SPDomainAddress:
            [data appendData:[self createIPV6Address]];
            break;
        case SPIPv6Address:
            [data appendData:[self createDomainAddress]];
            break;
    }
    
    [data appendData:[self createPort]];
    [_outGoSocket writeData:data withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_INIT];
}

- (void)socket:(GCDAsyncSocket *)socket startTransFormData:(NSData *)data {
    uint8_t *bytes = (uint8_t *)data.bytes;
    uint8_t remoteConnectStatus = bytes[1];
    
    NSUInteger urlLength = bytes[4];   // url 地址
    uint8_t *urlAddress = malloc(urlLength * sizeof(uint8_t));
    memcpy(urlAddress, &bytes + 5, urlLength);
    NSData *urlData = [NSData dataWithBytes:urlAddress length:urlLength];
    NSString *urlString = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
    
    NSUInteger portLength = bytes[5 + urlLength];
    uint16_t port;
    memcpy(&port, &bytes + 5 + urlLength, portLength);
    _requestPort = port;
    
    if (remoteConnectStatus == 0x00) {
        DDLogVerbose(@"connect to remote HOST:%@ Port:%d Success", urlString, port);
        [_inComeSocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
    } else {
        DDLogVerbose(@"connect to remote HOST:%@ Port:%d failed", urlString, port);
        [_outGoSocket disconnectAfterReading];
    }
}

- (void)socket:(GCDAsyncSocket *)socket transFormingData:(NSData *)data {
    if (socket == _inComeSocket) {
        if (_delegate && [_delegate respondsToSelector:@selector(connectFromIncomeData:)]) {
            [_delegate connectFromIncomeData:data.length];
        }
        
        _dataTotalWrite += data.length;
        [_outGoSocket writeData:data withTimeout:-1 tag:SOCKS_OUTGOING_WRITE];
        return ;
    }
    
    if (socket == _outGoSocket) {
        if (_delegate && [_delegate respondsToSelector:@selector(connectFromOutgoData:)]) {
            [_delegate connectFromOutgoData:data.length];
        }
        
        _dataTotalRead += data.length;
        [_inComeSocket writeData:data withTimeout:-1 tag:SOCKS_INCOMING_WRITE];
        return ;
    }
}

#pragma mark - After Write Method
// 发送 协商协议类型之后等待获得数据
- (void)socketWithResponseSocketOn:(GCDAsyncSocket *)socket {
    [socket readDataWithTimeout:-1 tag:SOCKS_OPEN];
}

- (void)socketWithConnectInit:(GCDAsyncSocket *)socket {
    [socket readDataWithTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_REPLY];
}

- (void)socketResponseSocket:(GCDAsyncSocket *)socket {
    [_outGoSocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
    [_inComeSocket readDataWithTimeout:-1 tag:SOCKS_OUTGOING_READ];
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


- (NSData *)createIPv4Address {
    NSMutableData *data = [NSMutableData data];
    
    // IPv4 地址长度
    uint8_t type = 1;
    [data appendBytes:&type length:1];
    
    // URL 地址
    NSUInteger urlLength = INET_ADDRSTRLEN;
    uint8_t *address = malloc(urlLength * sizeof(uint8_t));
    
    // IP地址二进制化
    NSData *addressData = [_requestURL dataUsingEncoding:NSUTF8StringEncoding];
    inet_pton(AF_INET, (char *)(addressData.bytes), address);
    
    [data appendBytes:&address length:urlLength];
    
    return data;
}

- (NSData *)createIPV6Address {
    NSMutableData *data = [NSMutableData data];
    
    uint8_t type = 4;
    [data appendBytes:&type length:1];
    
    NSUInteger urlLength = INET6_ADDRSTRLEN;
    uint8_t *address = malloc(urlLength * sizeof(uint8_t));
    
    //二进制化
    NSData *addressData = [_requestURL dataUsingEncoding:NSUTF8StringEncoding];
    inet_pton(AF_INET6, (char *)(addressData.bytes), address);
    
    [data appendBytes:&addressData length:urlLength];
    
    return data;
}

- (NSData *)createDomainAddress {
    NSMutableData *data = [NSMutableData data];
    
    return data;
}

- (NSData *)createPort {
    NSMutableData *data = [NSMutableData data];
    uint16_t rawPort = NSSwapHostShortToBig(_requestPort);
    [data appendBytes:&rawPort length:2];
    return data;
}

- (BOOL)checkSocket:(GCDAsyncSocket *)socket {
    return _inComeSocket == socket;
}

- (SPIPAddressType)checkAddressType:(NSString *)address {
    SPIPAddressType type = SPIPv4Address;
    return type;
}

@end
