//
//  NSString+convertData.m
//  Socks5 Proxy
//
//  Created by zkhCreator on 16/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "NSString+convertData.h"

@implementation NSString (convertData)

- (NSData *)convertData {
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

@end
