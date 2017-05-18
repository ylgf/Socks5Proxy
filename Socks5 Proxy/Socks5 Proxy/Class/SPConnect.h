//
//  SPConnect.h
//  Socks5 Proxy
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@protocol SPConnectDelegate <NSObject>

- (void)connectFromIncomeData:(NSUInteger) dataLength;
- (void)connectFromOutgoData:(NSUInteger) dataLength;

@end

@interface SPConnect : NSObject

@property (nonatomic, weak) id<SPConnectDelegate> delegate;
@property (nonatomic, assign) NSUInteger dataTotalRead;
@property (nonatomic, assign) NSUInteger dataTotalWrite;
@property (nonatomic, assign) NSUInteger tag;
@property (nonatomic, strong) GCDAsyncSocket *outGoSocket;
@property (nonatomic, strong) GCDAsyncSocket *inComeSocket;

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket;
- (void)startConnectWithData:(NSData *)data;
- (void)startConnect;
- (void)disconnect;
- (BOOL)checkSocket:(GCDAsyncSocket *)socket;

@end
