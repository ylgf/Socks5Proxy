//
//  ViewController.m
//  Socks5 Proxy
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "ViewController.h"
#import "SPServer.h"
#import "SPSocketUtil.h"

@interface ViewController()

@property (nonatomic, strong) SPServer *server;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) int port;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_methodTextField removeAllItems];
    [_methodTextField addItemsWithObjectValues:[SPServer encrpyTypes]];
    [_methodTextField selectItemAtIndex:0];
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    
    NSString *host = [userDefault stringForKey:@"Socks5ProxyLocalHost"];
    if (host) {
        [_hostLabel setStringValue: host];
    }
    
    NSString *hostPort = [userDefault stringForKey:@"Socks5ProxyLocalHostPort"];
    if (hostPort) {
        [_PortLabel setStringValue:hostPort];
    }
}

- (IBAction)start:(id)sender {
    
    if (!_hostLabel.stringValue || !_PortLabel.integerValue) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"请填写连接地址和端口"];
        [alert addButtonWithTitle:@"好的"];
        [alert runModal];
        return ;
    }

    _server = [[SPServer alloc] initWithHost:_hostLabel.stringValue port:_PortLabel.integerValue encryptionType: [[SPServer encrpyTypes] objectAtIndex:_methodTextField.indexOfSelectedItem]];
    
    [_sendTF setStringValue:@""];
    [_returnTF setStringValue:@""];

    
    [[NSUserDefaults standardUserDefaults] setValue:_PortLabel.stringValue forKey:@"Socks5ProxyLocalHostPort"];
    [[NSUserDefaults standardUserDefaults] setValue:_hostLabel.stringValue forKey:@"Socks5ProxyLocalHost"];
    
    [_server start];
}

- (IBAction)stop:(id)sender {
    DDLogVerbose(@"Server Stop");
    [_server stop];
}

- (IBAction)sendString:(id)sender {
    DDLogVerbose(@"Server Send Message");
    if (!_server) {
        [_returnTF setStringValue:@"请先点击开始"];
    }
    
    [_server sendStringToRemote:_sendTF.stringValue];
}

- (IBAction)Descrypt:(id)sender {
    
}

@end
