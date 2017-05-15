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
    [_remoteSocket setDelegate:self];
    [_remoteSocket readDataWithTimeout:-1 tag:0];
}

- (void)stop {
    [_remoteSocket disconnectAfterReadingAndWriting];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (sock == _remoteSocket) {
        switch (tag) {
            case SPCheckSOCKSVersionStatus:
                [sock writeData:[self dataFromHexString:@"52"] withTimeout:-1 tag:SPCheckSOCKSVersionStatus];
                break;
            case SPCheckAuthStatus:
                if ([self checkData:data]) {
                    [sock writeData:[self dataFromHexString:@"502"] withTimeout:-1 tag:SPCheckAuthStatus];
                } else {
                    [sock writeData:[self dataFromHexString:@"5ff"] withTimeout:-1 tag:SPCheckAuthStatus];
                }
                break;
            case SPSendMessageStatus:
                [self receiveDataFromRemote:data];
                break;
        }
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (sock == _remoteSocket) {
        switch (tag) {
            case SPCheckSOCKSVersionStatus:
                [_remoteSocket readDataWithTimeout:-1 tag:SPCheckAuthStatus];
                break;
            case SPCheckAuthStatus:
                [_remoteSocket readDataWithTimeout:-1 tag:SPSendMessageStatus];
                break;
            case SPSendMessageStatus:
                break;
        }
    }
}

- (BOOL)checkData:(NSData *)data {
    NSDictionary *jsonObject=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    NSString *userName = [jsonObject objectForKey:@"username"];
    NSString *password = [jsonObject objectForKey:@"password"];
    if ([userName isEqualToString:@"admin"] && [password isEqualToString: @"admin888"]) {
        return true;
    }
    return false;
}

- (void)receiveDataFromRemote:(NSData *)data {
    NSData *correctData = [data aes256_decrypt:@"helloworld"];
//    NSData *currentData = [NSData datawithbytes]
    NSString *string = [[NSString alloc] initWithData:correctData encoding:NSUTF8StringEncoding];
    NSDictionary *dic = @{@"info" : string , @"socket" : self};
    [[NSNotificationCenter defaultCenter] postNotificationName:receiveStringNotification object:nil userInfo:dic];
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


@end
