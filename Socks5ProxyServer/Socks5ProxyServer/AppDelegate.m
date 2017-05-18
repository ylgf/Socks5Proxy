//
//  AppDelegate.m
//  Socks5ProxyServer
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "AppDelegate.h"
#import "SPSocketUtil.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    // Xcode log
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    // Mac OS X log
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    // write to File
    DDFileLogger *fileLog = [[DDFileLogger alloc] init];
    if (fileLog) {
        NSLog(@"%@", fileLog.currentLogFileInfo.filePath);
        [DDLog addLogger:fileLog];
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
