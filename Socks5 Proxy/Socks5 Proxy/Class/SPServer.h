//
//  SPServer.h
//  Socks5 Proxy
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPServer : NSObject

- (instancetype)initWithHost:(NSString *)address port:(int)port encryptionType:(NSString *)type;
- (void)start;
- (void)stop;
- (void)sendStringToRemote:(NSString *)string;

+ (NSArray *)encrpyTypes;

@end
