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

@end

@implementation SPConnect

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket {
    if (self = [super init]) {
        _inComeSocket = socket;
        _remoteURL = [SPConfigManager shared].remoteAddress;
        _remotePort = [SPConfigManager shared].remotePort;
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
        if (_delegate && [_delegate respondsToSelector:@selector(connectFromIncomeData:)]) {
            [_delegate connectFromIncomeData:data.length];
        }
        
        _dataTotalWrite += data.length;
        [_outGoSocket writeData:data withTimeout:-1 tag:SOCKS_OUTGOING_WRITE];
        
        [_outGoSocket readDataWithTimeout:-1 tag:SOCKS_OUTGOING_READ];
        [_inComeSocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
        return ;
    }
    
    if (socket == _outGoSocket) {
        if (_delegate && [_delegate respondsToSelector:@selector(connectFromOutgoData:)]) {
            [_delegate connectFromOutgoData:data.length];
        }
        
        _dataTotalRead += data.length;
        [_inComeSocket writeData:data withTimeout:-1 tag:SOCKS_INCOMING_WRITE];
        [_inComeSocket readDataWithTimeout:-1 tag:SOCKS_INCOMING_READ];
        [_outGoSocket readDataWithTimeout:-1 tag:SOCKS_OUTGOING_READ];
        return ;
    }
}

@end
