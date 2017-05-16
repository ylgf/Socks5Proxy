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



@interface SPConnect : NSObject


- (instancetype)initWithSocket:(GCDAsyncSocket*) socket remoteConfig:(SPRemoteConfig *)config;

- (void)startConnectWithData:(NSData *)data;
- (void)disconnect;

@end
