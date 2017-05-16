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

@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
@property (nonatomic, strong) SPRemoteConfig *remoteConfig;
@property (nonatomic, copy) NSData *currentData;

@end

@implementation SPConnect

- (instancetype)initWithSocket:(GCDAsyncSocket*) socket remoteConfig:(SPRemoteConfig *)config {
    if (self = [super init]) {
        _clientSocket = socket;
        _remoteSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create("com.zkhCreator.socket.queue", 0)];
        _remoteConfig = config;
    }
    return self;
}

- (void)disconnect {
    [_remoteSocket disconnectAfterReadingAndWriting];
}

- (void)startConnectWithData:(NSData *)data {
    DDLogVerbose(@"start connect");
    // 储存数据准备连接到远端的服务端。
    _currentData = data;
    NSError *error;
    BOOL isConnect = [_remoteSocket connectToHost:_remoteConfig.remoteAddress onPort:_remoteConfig.remotePort error:&error];
    if (isConnect) {
        DDLogVerbose(@"connect success");
        NSData *requestData = [self makeUpSendData:SPCheckSOCKSVersionStatus];
        [_remoteSocket writeData:requestData withTimeout:-1 tag:SPCheckSOCKSVersionStatus];
    } else {
        DDLogVerbose(@"connect failed");
    }
}

- (NSData *)makeUpSendData:(SPConnectStatus)tag {
    
    if (tag == SPCheckSOCKSVersionStatus) {
        NSMutableData *data = [NSMutableData data];
        // 协议请求包。
        unsigned char whole_byte;
        char byte_chars[3] = {'\5', '\1', '\0'};
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
        
        return [data copy];
    } else if (tag == SPCheckAuthStatus) {
        return [self userInfo];
    } else if (tag == SPSendMessageStatus) {
        // 组装请求包
        NSMutableData *data = [NSMutableData data];
        NSString *string = [NSString stringWithFormat:@"5101"];
        [data appendData:[self dataFromHexString:string]];
        
        // URL
        NSString *url = _remoteConfig.remoteAddress;
        [data appendData:[url dataUsingEncoding:NSUTF8StringEncoding]];
        // Prot
        [data appendData:[self dataFromHexString:[NSString stringWithFormat:@"%ld", _remoteConfig.remotePort]]];
        
        [data appendData:_currentData];
        
        return [[data copy] aes256_encrypt:@"helloworld"];
    }
    
    return nil;
}

- (NSData *)dataFromHexString:(NSString *)string
{
    string = [string lowercaseString];
    NSMutableData *data= [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    NSUInteger length = string.length;
    while (i < length - 1) {
        char c = [string characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [string characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}

#pragma mark - delegate

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (sock == _remoteSocket) {
        switch (tag) {
            case SPCheckSOCKSVersionStatus:
                [sock readDataWithTimeout:-1 tag:SPCheckSOCKSVersionStatus];
                break;
            case SPCheckAuthStatus:
                [sock readDataWithTimeout:-1 tag:SPCheckAuthStatus];
                break;
            case SPSendMessageStatus:
                [sock readDataWithTimeout:-1 tag:SPSendMessageStatus];
                break;
        }
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    if (sock == _remoteSocket) {
        switch (tag) {
            case SPCheckSOCKSVersionStatus:
                [sock writeData:[self makeUpSendData:SPCheckAuthStatus] withTimeout:-1 tag:SPCheckAuthStatus];
                break;
            case SPCheckAuthStatus:
                if ([self checkAfterAuth:data]) {
                    DDLogVerbose(@"check userName && password Success");
                    [sock writeData:[self makeUpSendData:SPSendMessageStatus] withTimeout:-1 tag:SPSendMessageStatus];
                } else {
                    DDLogVerbose(@"check userName && password Error");
                    NSLog(@"验证不通过，请检查用户名密码");
                    [sock disconnect];
                }
                break;
            case SPSendMessageStatus:
                [self afterReceiveData:data];
                break;
        }
    }
}

- (NSData *)userInfo {
    NSString *userName = @"admin";
    NSString *password = @"admin888";
    
    NSDictionary *dic = @{@"username" : userName, @"password" : password};
    NSError *err;
    return [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&err];
}

- (void)afterReceiveData:(NSData *)data {
    NSDictionary *dic = @{@"connect": self, @"data": data};
    [[NSNotificationCenter defaultCenter] postNotificationName:receiveStringNotification object:self userInfo:dic];
    [self disconnect];
}

- (BOOL)checkAfterAuth:(NSData *)data {
    if ([data isEqualToData:[self dataFromHexString:@"502"]]) {
        return YES;
    } else {
        return NO;
    }
}


@end
