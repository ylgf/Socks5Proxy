//
//  SPServer.h
//  Socks5 Proxy
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@interface SPServer : NSObject
@property (nonatomic, strong) GCDAsyncSocket *localSocket;

- (void)start;
- (void)stop;
- (void)sendStringToRemote:(NSString *)string;

+ (NSArray *)encrpyTypes;

@end
