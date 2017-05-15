//
//  ViewController.m
//  Socks5ProxyServer
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "ViewController.h"
#import "SPProxyServer.h"
#import "SPSocketUtil.h"

@interface ViewController()<GCDAsyncSocketDelegate>
@property (nonatomic, strong) SPProxyServer *server;
@property (weak) IBOutlet NSTextField *localPort;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:receiveStringNotification object:nil];
}

- (IBAction)startListen:(id)sender {
    NSInteger port = _localPort.integerValue;
    
    _server = [[SPProxyServer alloc] initWithListenPort:port];
    
    if (!_server) {
        NSLog(@"创建服务失败，请检查端口号");
    }
    
    [_server start];
}

- (void)receiveNotification:(NSNotification *)notification {
    if (notification.name == receiveStringNotification) {
        NSDictionary *dic = notification.userInfo;
        NSString *info = [dic objectForKey:@"info"];
        SPProxyConnect *conn = [dic objectForKey:@"connect"];
        [_receivedLabel setStringValue:[NSString stringWithFormat:@"%@ : %@", conn, info]];
    }
}

@end
