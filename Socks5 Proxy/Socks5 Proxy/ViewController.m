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
@property (weak) IBOutlet NSTextField *hostLabel;
@property (weak) IBOutlet NSTextField *PortLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_methodTextField removeAllItems];
    [_methodTextField addItemsWithObjectValues:[SPServer encrpyTypes]];
    [_methodTextField selectItemAtIndex:0];
    
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
    
}


@end
