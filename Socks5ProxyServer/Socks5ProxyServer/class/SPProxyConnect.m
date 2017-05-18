//
//  SPProxyConnect.m
//  Socks5ProxyServer
//
//  Created by zkhCreator on 15/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "SPProxyConnect.h"
#import "GCDAsyncSocket.h"
#import "SPSocketUtil.h"
#import "NSData+SPAES.h"

// 网络参数库
#include <arpa/inet.h>

@interface SPProxyConnect()
@property (nonatomic, strong) GCDAsyncSocket *inComeSocket; // 客户端 Socket
@property (nonatomic, strong) GCDAsyncSocket *outGoSocket; // 需要请求的远端 Socket

@property (nonatomic, copy) NSString *username; // 用于验证的用户名
@property (nonatomic, assign) uint8_t supportedMethod;  // 是否需要进行身份验证。

@property (nonatomic, copy) NSString *requestHost;  // 对应请求的服务端
@property (nonatomic, assign) short requestPort;    // 对应请求的端口

@property (nonatomic, assign) NSUInteger totalBytesWritten;     // 从income获得的字符总长度，即发往outgo的总长度
@property (nonatomic, assign) NSUInteger totalBytesRead;    // 从outgo服务端获取的字符总长度，即发往income的总长度

@end

@implementation SPProxyConnect

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket listenPort:(NSInteger)listenPort {
    if (!socket) {
        return nil;
    }
    
    if (self = [super init]) {
        _inComeSocket = socket;
        _outGoSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create("com.zkhCreator.server.request.queue", 0)];
    }
    
    return self;
}

- (void)connect {
    [_inComeSocket setDelegate:self];
    [self.inComeSocket readDataToLength:3 withTimeout:TIMEOUT_CONNECT tag:SOCKS_OPEN];
}

- (void)stop {
    [_inComeSocket disconnect];
}

#pragma mark - CocoaAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    switch (tag) {
        case SOCKS_OPEN:
            [self socksOpen:data socket:sock];
            break;
        case SOCKS_CONNECT_AUTH_INIT:
            [self socksConnectAuthInit:data socket:sock];
            break;
        case SOCKS_CONNECT_AUTH_USERNAME:
            [self socksConnectAuthUserName:data socket:sock];
            break;
        case SOCKS_CONNECT_AUTH_PASSWORD:
            [self socksConnectAuthPassword:data socket:sock];
            break;
        case SOCKS_CONNECT_INIT:
            [self socksConnectInit:data socket:sock];
            break;
        case SOCKS_CONNECT_IPv4:
            [self socksConnectIPV4:data socket:sock];
            break;
        case SOCKS_CONNECT_IPv6:
            [self socksConnectIPV6:data socket:sock];
            break;
        case SOCKS_CONNECT_DOMAIN_LENGTH:
            [self socksConnectDomainLength:data socket:sock];
            break;
        case SOCKS_CONNECT_DOMAIN:
            [self socksConnectDomain:data socket:sock];
        case SOCKS_CONNECT_PORT:
            [self socksConnectPort:data socket:sock];
            break;
        case SOCKS_INCOMING_READ:
        case SOCKS_OUTGOING_READ:
            [self socksTransformData:data socket:sock];
            break;
        default:
            break;
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    switch (tag) {
        case SOCKS_OPEN:
            [self socketResponseSocketONSocket:sock];
            break;
        case SOCKS_CONNECT_INIT:
            [self socketResponseSocketAuth:sock];
            break;
        case SOCKS_INCOMING_READ:
        case SOCKS_OUTGOING_READ:
            [self socketResponseSocket:sock];
            break;
        default:
            break;
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    // 对于已经成功连接的内容进行反馈，之后开启对应的服务。
    NSUInteger hostLength = [host lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSUInteger responseLength = 5 + hostLength + 2;
    uint8_t *responseBytes = malloc(responseLength * sizeof(uint8_t));
    responseBytes[0] = 5;
    responseBytes[1] = 0;
    responseBytes[2] = 0;
    responseBytes[3] = 3;
    responseBytes[4] = (uint8_t)hostLength;
    memcpy(responseBytes+5, [host UTF8String], hostLength);
    uint16_t bigEndianPort = NSSwapHostShortToBig(port);
    NSUInteger portLength = 2;
    memcpy(responseBytes+5+hostLength, &bigEndianPort, portLength);
    NSData *responseData = [NSData dataWithBytesNoCopy:responseBytes length:responseLength freeWhenDone:YES];
    [_inComeSocket writeData:responseData withTimeout:-1 tag:SOCKS_CONNECT_REPLY];
    [_inComeSocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
}

#pragma mark - Read Method

/* 
 +----+----------+----------+
 |VER | NMETHODS | METHODS  |
 +----+----------+----------+
 | 1  |    1     | 1 to 255 |
 +----+----------+----------+ */

// 检查 Socks Versin，反馈对应的 验证方法。
- (void)socksOpen:(NSData *)data socket:(GCDAsyncSocket *)socket {
    if (data.length >= 3) {
        uint8_t *bytes = (uint8_t *)data.bytes;
        uint8_t firstSupportedMethod = bytes[2];
        _supportedMethod = 0x00;
        
        // check Password Auth
        if (firstSupportedMethod == 0x02) {
            _supportedMethod = firstSupportedMethod;
        }
        
        // make up response
        //      +-----+--------+
        // NAME | VER | METHOD |
        //      +-----+--------+
        // SIZE |  1  |   1    |
        //      +-----+--------+
        //
        NSUInteger responseLength = 2;
        uint8_t *responseBytes = malloc(responseLength * sizeof(uint8_t));
        responseBytes[0] = 5;   // Socks Version 5;
        responseBytes[1] = _supportedMethod;
        
        NSData *responseData = [NSData dataWithBytes:responseBytes length:responseLength];
        [socket writeData:responseData withTimeout:-1 tag:SOCKS_OPEN];
    }
}

/*
 For username/password authentication the client's authentication request is
 
 field 1: version number, 1 byte (must be 0x01)
 field 2: username length, 1 byte
 field 3: username
 field 4: password length, 1 byte
 field 5: password
 Server response for username/password authentication:
 
 field 1: version, 1 byte
 field 2: status code, 1 byte.
 0x00 = success
 any other value = failure, connection must be closed
 */
// 进行账号密码的验证，继续监听 username
- (void)socksConnectAuthInit:(NSData *)data socket:(GCDAsyncSocket *)socket {
    // 确认是否进行验证
    if (data.length == 2) {
        uint8_t *bytes = (uint8_t *)data.bytes;
        uint8_t version = bytes[0];
        uint8_t userNameLength = bytes[1];
        DDLogVerbose(@"Auth Version %d. Reading UserName", version);
        [socket readDataToLength:userNameLength + 1 withTimeout:-1 tag:SOCKS_CONNECT_AUTH_USERNAME];
    }
}

// 获得userName，继续监听password
- (void)socksConnectAuthUserName:(NSData *)data socket:(GCDAsyncSocket *)socket {
    if (data.length >= 2) {
        NSData *usernameData = [data subdataWithRange:NSMakeRange(0, data.length - 1)];
        NSString *usernameString = [[NSString alloc] initWithData:usernameData encoding:NSUTF8StringEncoding];
        _username = usernameString;
        
        DDLogVerbose(@"Auth UserName: %@", usernameString);
        
        NSData *passwordLengthData = [data subdataWithRange:NSMakeRange(data.length - 1, 1)];
        if (passwordLengthData.length == 1) {
            uint8_t *passwordLengthBytes = (uint8_t *)passwordLengthData.bytes;
            uint8_t passwordLength = passwordLengthBytes[0];
            DDLogVerbose(@"Reading password of length:%d", passwordLength);
            [socket readDataToLength:passwordLength withTimeout:-1 tag:SOCKS_CONNECT_AUTH_PASSWORD];
        }
    }
}

// 获得密码，同时验证账号密码并进行返回。
- (void)socksConnectAuthPassword:(NSData *)data socket:(GCDAsyncSocket *)socket {
    NSString *passwordString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if ([self checkUserName:_username password:passwordString]) {
        uint8_t success[2] = {0x01, 0x00};
        NSData *responseData = [NSData dataWithBytes:&success length:2];
        [socket writeData:responseData withTimeout:-1 tag:SOCKS_CONNECT_INIT];
    } else {
        uint8_t failure[2] = {0x01, 0x02};
        NSData *responseData = [NSData dataWithBytes:&failure length:2];
        [socket writeData:responseData withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_INIT];
        [socket disconnectAfterWriting];
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
// 服务端和客户端进行连接
- (void)socksConnectInit:(NSData *)data socket:(GCDAsyncSocket *)socket {
    uint8_t *requestBytes = (uint8_t *)data.bytes;
    uint8_t addressType = requestBytes[3];
    
    if (addressType == 1) {
        [socket readDataToLength:4 withTimeout:-1 tag:SOCKS_CONNECT_IPv4];
    } else if (addressType == 3){
        [socket readDataToLength:1 withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_DOMAIN_LENGTH];
    } else if (addressType == 4) {
        [socket readDataToLength:16 withTimeout:-1 tag:SOCKS_CONNECT_IPv6];
    }
}

// 解析IPV4，获得对应的请求端口
- (void)socksConnectIPV4:(NSData *)data socket:(GCDAsyncSocket *)socket {
    uint8_t *address = malloc(INET_ADDRSTRLEN * sizeof(uint8_t));
    // 将地址从二进制转换为十进制
    inet_ntop(AF_INET, data.bytes, (char *)address, INET_ADDRSTRLEN);
    _requestHost = [[NSString alloc] initWithBytesNoCopy:address length:INET_ADDRSTRLEN encoding:NSUTF8StringEncoding freeWhenDone:YES];
    [socket readDataToLength:2 withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_PORT];
}

// 解析IPV6地址，获得对应的请求端口
- (void)socksConnectIPV6:(NSData *)data socket:(GCDAsyncSocket *)socket {
    uint8_t *address = malloc(INET6_ADDRSTRLEN * sizeof(uint8_t));
    inet_ntop(AF_INET6, data.bytes, (char *)address, INET6_ADDRSTRLEN);
    _requestHost = [[NSString alloc] initWithBytesNoCopy:address length:INET6_ADDRSTRLEN encoding:NSUTF8StringEncoding freeWhenDone:YES];
    [socket readDataToLength:2 withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_PORT];
}

// 解析域名，获得域名长度，并请求对应域名地址
- (void)socksConnectDomainLength:(NSData *)data socket:(GCDAsyncSocket *)socket {
    uint8_t *bytes = (uint8_t *)data.bytes;
    uint8_t addressLength = bytes[0];
    [socket readDataToLength:addressLength withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_DOMAIN];
}

// 保存对应的域名地址，获得端口
- (void)socksConnectDomain:(NSData *)data socket:(GCDAsyncSocket *)socket {
    _requestHost = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
    
    [socket readDataToLength:2 withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_PORT];
}

// 分析获得接口，并根据接口与请求的服务器相连接。
- (void)socksConnectPort:(NSData *)data socket:(GCDAsyncSocket *)socket {
    uint16_t rawPort;
    memcpy(&rawPort, [data bytes], 2);
    _requestPort = NSSwapBigShortToHost(rawPort);
    
    // 与远端服务器进行通信
    NSError *error;
    BOOL outgoConnect = [_outGoSocket connectToHost:_requestHost onPort:_requestPort error:&error];
    if (outgoConnect) {
        DDLogVerbose(@"connect outgo host:%@ port:%d success", _requestHost, _requestPort);
    } else {
        DDLogVerbose(@"connect outgo host:%@ port:%d failed。 reason: code: %ld userInfo: %@", _requestHost, _requestPort, (long)error.code, error.userInfo);
    }
}

- (void)socksTransformData:(NSData *)data socket:(GCDAsyncSocket *)socket {
    // 将从income收到的数据发往outgo
    if (socket == _inComeSocket) {
        [_outGoSocket writeData:data withTimeout:-1 tag:SOCKS_OUTGOING_WRITE];
        _totalBytesWritten += data.length;
        
        if (_delegate && [_delegate respondsToSelector:@selector(socket:didWriteDataLength:)]) {
            [_delegate socket:socket didWriteDataLength:data.length];
        }
    }
    
    //将从outGo收到的数据发往inCome
    if (socket == _outGoSocket) {
        [_inComeSocket writeData:data withTimeout:-1 tag:SOCKS_INCOMING_WRITE];
        _totalBytesRead += data.length;
        
        if (_delegate && [_delegate respondsToSelector:@selector(socket:didReadDataLength:)]) {
            [_delegate socket:socket didWriteDataLength:data.length];
        }
    }
}

#pragma mark - Write Method
// 完成对版本的协商后，等待验证身份或者直接进行连接
- (void)socketResponseSocketONSocket:(GCDAsyncSocket *)socket {
    // 在写完数据后等待远端对数据进行相应，根据不同的支持模式来响应不同的消息情况。
    if (_supportedMethod == 0x00) {
        [socket readDataToLength:4 withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_INIT];
        return ;
    }
    
    if (_supportedMethod == 0x02) {
        // read first 2 bytes of socks auth
        [socket readDataToLength:2 withTimeout:-1 tag:SOCKS_CONNECT_AUTH_INIT];
        return ;
    }
}

//  完成身份验证后，等待开始连接
- (void)socketResponseSocketAuth:(GCDAsyncSocket *)socket {
    [socket readDataToLength:4 withTimeout:TIMEOUT_CONNECT tag:SOCKS_CONNECT_INIT];
}

- (void)socketResponseSocket:(GCDAsyncSocket *)socket {
    [_outGoSocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
    [_inComeSocket readDataWithTimeout:-1 tag:SOCKS_OUTGOING_READ];
}

#pragma mark - Check Method
- (BOOL) checkUserName:(NSString *)username password:(NSString *)password {
    if ([username isEqualToString:@"admin"] && [password isEqualToString:@"admin888"]) {
        return YES;
    }
    return NO;
}



- (void)receiveDataFromRemote:(NSData *)data {
    NSData *correctData = [data aes256_decrypt:@"helloworld"];
//    NSData *currentData = [NSData datawithbytes]
    NSString *string = [[NSString alloc] initWithData:correctData encoding:NSUTF8StringEncoding];
    NSDictionary *dic = @{@"info" : string , @"socket" : self};
    [[NSNotificationCenter defaultCenter] postNotificationName:receiveStringNotification object:nil userInfo:dic];
}

- (BOOL)checkSocket:(GCDAsyncSocket *)socket {
    return _inComeSocket == socket;
}

@end
