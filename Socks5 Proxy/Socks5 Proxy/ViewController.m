//
//  ViewController.m
//  Socks5 Proxy
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "ViewController.h"
#import "SPServer.h"

@interface ViewController()

@property (nonatomic, strong) SPServer *server;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) int port;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _host = @"127.0.0.1";
    _port = 55555;
    
    [_methodTextField removeAllItems];
    [_methodTextField addItemsWithObjectValues:[SPServer encrpyTypes]];
    [_methodTextField selectItemAtIndex:0];
    
}

- (IBAction)start:(id)sender {

    _server = [[SPServer alloc] initWithHost:_host port:_port encryptionType: [[SPServer encrpyTypes] objectAtIndex:_methodTextField.indexOfSelectedItem]];
    
    [_sendTF setStringValue:@""];
    [_returnTF setStringValue:@""];
    [self updateUI];

    [_server start];
}

- (IBAction)stop:(id)sender {
    [_server stop];
}

- (IBAction)sendString:(id)sender {
    
    if (!_server) {
        [_returnTF setStringValue:@"请先点击开始"];
    }
    [_server sendStringToRemote:_sendTF.stringValue];
}

- (IBAction)Descrypt:(id)sender {
    
}

- (void)updateUI {
    [_hostLabel setStringValue:_host];
    [_PortLabel setStringValue:[NSString stringWithFormat:@"%d", _port]];
}


@end
