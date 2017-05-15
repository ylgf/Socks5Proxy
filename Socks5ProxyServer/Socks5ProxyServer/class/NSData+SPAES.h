//
//  NSData+SPAES.h
//  Socks5 Proxy
//
//  Created by zkhCreator on 15/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (SPAES)

-(NSData *) aes256_encrypt:(NSString *)key;
-(NSData *) aes256_decrypt:(NSString *)key;

@end
