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

/*
 +----+-----+-------+------+----------+----------+
 |VER | CMD |  RSV  | ATYP | DST.ADDR | DST.PORT |
 +----+-----+-------+------+----------+----------+
 | 1  |  1  | X'00' |  1   | Variable |    2     |
 +----+-----+-------+------+----------+----------+
 
 o  VER    protocol version: X'05'
 o  CMD
	o  CONNECT X'01'
	o  BIND X'02'
	o  UDP ASSOCIATE X'03'
 o  RSV    RESERVED
 o  ATYP   address type of following address
	o  IP V4 address: X'01'
	o  DOMAINNAME: X'03'
	o  IP V6 address: X'04'
 o  DST.ADDR       desired destination address
 o  DST.PORT desired destination port in network octet
 order
 */

typedef NS_ENUM(NSInteger, SPSOCKS5RequestPhase) {
    SPSOCKS5RequestPhaseHeaderFragment = 10,
    SPSOCKS5RequestPhaseAddressType,
    SPSOCKS5RequestPhaseIPv4Address,
    SPSOCKS5RequestPhaseIPv6Address,
    SPSOCKS5RequestPhaseDomainNameLength,
    SPSOCKS5RequestPhaseDomainName,
    SPSOCKS5RequestPhasePort
};

typedef NS_ENUM(uint8_t, SPSOCKS5AddressType) {
    SPSOCKS5AddressTypeIPv4 = 0x01,
    SPSOCKS5AddressTypeIPv6 = 0x04,
    SPSOCKS5AddressTypeDomainName = 0x03
};

typedef NS_ENUM(uint8_t, SPSOCKS5Command) {
    SPSOCKS5CommandConnect = 0x01,
    SPSOCKS5CommandBind = 0x02,
    SPSOCKS5CommandUDPAssociate = 0x03
};

/*
 +----+-----+-------+------+----------+----------+
 |VER | REP |  RSV  | ATYP | BND.ADDR | BND.PORT |
 +----+-----+-------+------+----------+----------+
 | 1  |  1  | X'00' |  1   | Variable |    2     |
 +----+-----+-------+------+----------+----------+
 
 o  VER    protocol version: X'05'
 o  REP    Reply field:
	o  X'00' succeeded
	o  X'01' general SOCKS server failure
	o  X'02' connection not allowed by ruleset
	o  X'03' Network unreachable
	o  X'04' Host unreachable
	o  X'05' Connection refused
	o  X'06' TTL expired
	o  X'07' Command not supported
	o  X'08' Address type not supported
	o  X'09' to X'FF' unassigned
	o  RSV    RESERVED
 o  ATYP   address type of following address
	o  IP V4 address: X'01'
	o  DOMAINNAME: X'03'
	o  IP V6 address: X'04'
 o  BND.ADDR       server bound address
 o  BND.PORT       server bound port in network octet order
 */

typedef NS_ENUM(uint8_t, SPSOCKS5HandshakeReplyType) {
    SPSOCKS5HandshakeReplySucceeded = 0x00,
    SPSOCKS5HandshakeReplyGeneralSOCKSServerFailure = 0x01,
    SPSOCKS5HandshakeReplyConnectionNotAllowedByRuleset = 0x02,
    SPSOCKS5HandshakeReplyNetworkUnreachable = 0x03,
    SPSOCKS5HandshakeReplyHostUnreachable = 0x04,
    SPSOCKS5HandshakeReplyConnectionRefused = 0x05,
    SPSOCKS5HandshakeReplyTTLExpired = 0x06,
    SPSOCKS5HandshakeReplyCommandNotSupported = 0x07,
    SPSOCKS5HandshakeReplyAddressTypeNotSupported = 0x08
};

/*
 o  X'00' NO AUTHENTICATION REQUIRED
 o  X'01' GSSAPI
 o  X'02' USERNAME/PASSWORD
 o  X'03' to X'7F' IANA ASSIGNED
 o  X'80' to X'FE' RESERVED FOR PRIVATE METHODS
 o  X'FF' NO ACCEPTABLE METHODS
 */

typedef NS_ENUM(uint8_t, SPSOCKS5AuthenticationMethod) {
    SPSOCKS5AuthenticationNone = 0x00,
    SPSOCKS5AuthenticationGSSAPI = 0x01,
    SPSOCKS5AuthenticationUsernamePassword = 0x02
};
