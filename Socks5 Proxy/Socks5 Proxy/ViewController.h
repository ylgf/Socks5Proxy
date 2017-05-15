//
//  ViewController.h
//  Socks5 Proxy
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (weak) IBOutlet NSTextField *hostLabel;
@property (weak) IBOutlet NSTextField *PortLabel;
@property (weak) IBOutlet NSButton *StartButton;
@property (weak) IBOutlet NSButton *StopButton;
@property (weak) IBOutlet NSComboBox *methodTextField;
@property (weak) IBOutlet NSTextField *sendTF;
@property (weak) IBOutlet NSTextField *returnTF;

@end

