//
//  ViewController.m
//  Socks5ProxyServer
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

@interface ViewController()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *listenSocket;
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create("com.zkhCreator.com.received.queue", 0)];
    
    
}

- (IBAction)startListen:(id)sender {
    NSError *error;
    BOOL isListen =  [_listenSocket acceptOnPort:55556 error:&error];
    if (isListen) {
        NSLog(@"监听成功");
    } else {
        NSLog(@"监听失败");
    }
}

#pragma mark - delegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"current:%@", sock);
    
    if (newSocket) {
        _clientSocket = newSocket;
        NSLog(@"保留 socket 接口成功");
        
        NSLog(@"%@", [NSString stringWithFormat:@"localhost:%@ localProt: %hu", newSocket.localHost, newSocket.localPort]);
        NSLog(@"%@", [NSString stringWithFormat:@"connectHost:%@ connectPort:%hu", newSocket.connectedHost, newSocket.connectedPort]);
        
        [_clientSocket readDataWithTimeout:-1 tag:0];
    }
    
    
    
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"%@", data);
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"%@", string);
}



@end
