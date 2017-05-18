//
//  SPConnect.h
//  Socks5 Proxy
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@interface SPRemoteConfig : NSObject

@property (nonatomic, copy, readonly) NSString *remoteAddress;
@property (nonatomic, assign, readonly) NSInteger remotePort;

- (instancetype)initWithAddress:(NSString *)address port:(NSInteger)port;

@end

@protocol SPConnectDelegate <NSObject>

- (void)connectFromIncomeData:(NSUInteger) dataLength;
- (void)connectFromOutgoData:(NSUInteger) dataLength;

@end

@interface SPConnect : NSObject

@property (nonatomic, weak) id<SPConnectDelegate> delegate;
@property (nonatomic, assign) NSUInteger dataTotalRead;
@property (nonatomic, assign) NSUInteger dataTotalWrite;

- (instancetype)initWithSocket:(GCDAsyncSocket*) socket remoteConfig:(SPRemoteConfig *)config;
- (instancetype)initWithSocket:(GCDAsyncSocket *)socket;
- (void)startConnectWithData:(NSData *)data;
- (void)startConnect;
- (void)disconnect;
- (BOOL)checkSocket:(GCDAsyncSocket *)socket;

@end
