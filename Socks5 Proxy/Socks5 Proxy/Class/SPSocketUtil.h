//
//  SPSocketUtil.h
//  Socks5 Proxy
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

static NSString * const receiveStringNotification = @"com.zkhCreator.receiveData.NotificationCenter";

#if DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif

// 判断当前请求状态
typedef NS_ENUM(NSInteger, SPConnectStatus) {
    SPCheckSOCKSVersionStatus = 0,
    SPCheckAuthStatus = 1,
    SPSendMessageStatus = 2,
};


/* +----+----------+----------+
 |VER | NMETHODS | METHODS  |
 +----+----------+----------+
 | 1  |    1     | 1 to 255 |
 +----+----------+----------+ */

#define SPSOCKS4Version @"4";
#define SPSOCKS5Version @"5";


#define SOCKS_OPEN             10100
#define SOCKS_CONNECT_AUTH_INIT     10101
#define SOCKS_CONNECT_AUTH_USERNAME     10102
#define SOCKS_CONNECT_AUTH_PASSWORD     10103

#define SOCKS_CONNECT_INIT     10200
#define SOCKS_CONNECT_IPv4     10201
#define SOCKS_CONNECT_DOMAIN   10202
#define SOCKS_CONNECT_DOMAIN_LENGTH   10212
#define SOCKS_CONNECT_IPv6     10203
#define SOCKS_CONNECT_PORT     10210
#define SOCKS_CONNECT_REPLY    10300
#define SOCKS_INCOMING_READ    10400
#define SOCKS_INCOMING_WRITE   10401
#define SOCKS_OUTGOING_READ    10500
#define SOCKS_OUTGOING_WRITE   10501
