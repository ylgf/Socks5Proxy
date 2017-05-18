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
#import "SPConfigManager.h"

#import <arpa/inet.h>


@interface SPConnect()<GCDAsyncSocketDelegate>

@property (nonatomic, copy) NSData *currentData;
@property (nonatomic, strong) NSString *requestURL;
@property (nonatomic, assign) uint16_t requestPort;

@property (nonatomic, copy) NSString *remoteURL;
@property (nonatomic, assign) int16_t remotePort;

@property (nonatomic, assign) BOOL startConnectRequest;
@property (nonatomic, assign) BOOL finishConnect;

@end

@implementation SPConnect

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket {
    if (self = [super init]) {
        _inComeSocket = socket;
        _remoteURL = [SPConfigManager shared].remoteAddress;
        _remotePort = [SPConfigManager shared].remotePort;
        _outGoSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create("com.zkhCreator.socket.queue", 0)];
        _startConnectRequest = NO;
        _finishConnect = NO;
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
    BOOL isConnect = [_outGoSocket connectToHost:_remoteURL onPort:_remotePort error:&error];
    if (isConnect) {
        DDLogVerbose(@"start connect: Connect To Remote Server Succeed");
//        [self socketOpenSOCKS5];
        [_inComeSocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
        [_outGoSocket readDataWithTimeout:-1 tag:SOCKS_OUTGOING_READ];
    } else {
        DDLogVerbose(@"start connect: Connect To Remote Server Failed");
    }
}

- (void)startConnect {
    DDLogVerbose(@"start proxy");
    NSError *error;
    BOOL isConnect = [_outGoSocket connectToHost:_remoteURL onPort:_remotePort error:&error];
    if (isConnect) {
        DDLogVerbose(@"start Connect: Connect to Remote Server Successed");
        [_inComeSocket setDelegate:self];
        [_inComeSocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
        [_outGoSocket readDataWithTimeout:-1 tag:SOCKS_OUTGOING_READ];
    } else {
        DDLogVerbose(@"start Connect: Connect to Remote Server failure");
        [_inComeSocket disconnect];
        [_outGoSocket disconnect];
    }
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
        [self socket:sock transFormingData:data];
}


#pragma mark - After Read Method
- (void)socket:(GCDAsyncSocket *)socket transFormingData:(NSData *)data {
    if (socket == _inComeSocket) {
        DDLogVerbose(@"Connect Success: Send %ld counts Data to Remote Server", data.length);
        if (_delegate && [_delegate respondsToSelector:@selector(connectFromIncomeData:)]) {
            [_delegate connectFromIncomeData:data.length];
        }
        
        _dataTotalWrite += data.length;
        
        NSData *encryptionData;
        // 首先判断是否已经完成连接，完成连接后的内容才进行加密
        if (_finishConnect) {
            // 已经完成连接
            if ([[SPConfigManager shared].encrypt isEqualToString:@"empty"]) {
                encryptionData = data;
            } else {
                encryptionData = [data aes256_encrypt:@"helloworld"];
            }
        } else {
            // 未完成连接
            encryptionData = data;
        }
        
        
        if (!_startConnectRequest && [self checkRequestResponseHeader:data]) {
            _startConnectRequest = YES;
        }
        
        [_outGoSocket writeData:encryptionData withTimeout:-1 tag:SOCKS_OUTGOING_WRITE];
        [_outGoSocket readDataWithTimeout:-1 tag:SOCKS_OUTGOING_READ];
        [_inComeSocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
        return ;
    }
    
    if (socket == _outGoSocket) {
        DDLogVerbose(@"Connect Success: receive %ld counts Data to Remote Server", data.length);
        if (_delegate && [_delegate respondsToSelector:@selector(connectFromOutgoData:)]) {
            [_delegate connectFromOutgoData:data.length];
        }
        
        _dataTotalRead += data.length;
        
        NSData *decryptionData;
        if (_finishConnect) {
            // 已经完成连接
            if ([[SPConfigManager shared].encrypt isEqualToString:@"empty"]) {
                decryptionData = data;
            } else {
                decryptionData = [data aes256_decrypt:@"helloworld"];
            }
        } else {
            // 未完成连接
            decryptionData = data;
        }
        
        if (!_finishConnect && _startConnectRequest && [self remoteConnectToRequestURL:data]) {
            _finishConnect = YES;
        }
        
        [_inComeSocket writeData:decryptionData withTimeout:-1 tag:SOCKS_INCOMING_WRITE];
        [_inComeSocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
        [_outGoSocket readDataWithTimeout:-1 tag:SOCKS_OUTGOING_READ];
        return ;
    }
}

- (BOOL)checkRequestResponseHeader:(NSData *)data {
    uint8_t *bytes = (uint8_t *)data.bytes;
    uint8_t version = bytes[0];
    uint8_t rep = bytes[1];
    
    if (version == 0x05 && rep == 0x01) {
        return YES;
    }
    
    return NO;
}

- (BOOL)remoteConnectToRequestURL:(NSData *)data {
    uint8_t *bytes = (uint8_t *)data.bytes;
    uint8_t version = bytes[0];
    uint8_t rep = bytes[1];
    uint8_t rsv = bytes[2];
    uint8_t atyp = bytes[3];
    
    if (version == 0x05 && rep == 0x00 && rsv == 0x00 && atyp == 0x03) {
        return YES;
    }
    
    return NO;
}

- (BOOL)checkSocket:(GCDAsyncSocket *)socket {
    return socket == _outGoSocket;
}

@end
