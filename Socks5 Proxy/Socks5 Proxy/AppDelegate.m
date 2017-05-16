//
//  AppDelegate.m
//  Socks5 Proxy
//
//  Created by zkhCreator on 14/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "SPQCWindowController.h"
#import <CoreImage/CoreImage.h>

@interface AppDelegate ()

@property (nonatomic, strong) SPQCWindowController *qcWC;
@property (nonatomic, strong) ViewController *vc;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)FeedBack:(NSMenuItem *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:zkh90644@gmail.com"]];
}

- (IBAction)showQCCode:(id)sender {
    NSString *localhost = self.vc.hostLabel.stringValue;
    NSString *localPort = self.vc.PortLabel.stringValue;
    
    if (localhost.length == 0 || localPort.length == 0) {
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"请填写连接地址和端口"];
        [alert addButtonWithTitle:@"好的"];
        [alert beginSheetModalForWindow:NSApplication.sharedApplication.mainWindow completionHandler:nil];
        return ;
    }
    
    NSString *contentMessage = [NSString stringWithFormat:@"sp://%@;%@", localhost, localPort];
    NSString *encodeingMessage = [[contentMessage dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    _qcWC = [[SPQCWindowController alloc] initWithMessage: encodeingMessage];
    
    if (_qcWC) {
        [_qcWC showWindow:self];
        [NSApp activateIgnoringOtherApps:true];
        [_qcWC.window makeKeyAndOrderFront:nil];
    } else {
        NSLog(@"qc Code生成失败");
    }
}

- (IBAction)scanQCCode:(id)sender {
    [self ScanQRCodeOnScreen];
}

- (ViewController *)vc {
    if (!_vc) {
        NSWindowController *wc = NSApplication.sharedApplication.mainWindow.windowController;
        NSViewController *wcvc = wc.window.contentViewController;
        
        if ([wcvc isKindOfClass:[ViewController class]]) {
            _vc = (ViewController *)wcvc;
        } else {
            _vc = [[ViewController alloc] init];
        }
    }
    return _vc;
}

- (void)ScanQRCodeOnScreen {
    /* displays[] Quartz display ID's */
    CGDirectDisplayID   *displays = nil;
    
    CGError             err = CGDisplayNoErr;
    CGDisplayCount      dspCount = 0;
    
    /* How many active displays do we have? */
    // 获得当前界面所存在的所有可是窗口数目
    err = CGGetActiveDisplayList(0, NULL, &dspCount);
    
    /* If we are getting an error here then their won't be much to display. */
    if(err != CGDisplayNoErr)
    {
        NSLog(@"Could not get active display count (%d)\n", err);
        return;
    }
    
    // 获得所有科室窗口
    /* Allocate enough memory to hold all the display IDs we have. */
    displays = calloc((size_t)dspCount, sizeof(CGDirectDisplayID));
    
    // Get the list of active displays
    err = CGGetActiveDisplayList(dspCount,
                                 displays,
                                 &dspCount);
    
    /* More error-checking here. */
    if(err != CGDisplayNoErr)
    {
        NSLog(@"Could not get active display list (%d)\n", err);
        return;
    }
    
    CIDetector *detector = [CIDetector detectorOfType:@"CIDetectorTypeQRCode"
                                              context:nil
                                              options:@{ CIDetectorAccuracy:CIDetectorAccuracyHigh }];
    
    for (unsigned int displaysIndex = 0; displaysIndex < dspCount; displaysIndex++)
    {
        /* Make a snapshot image of the current display. */
        // 截取可视窗口的区域
        CGImageRef image = CGDisplayCreateImage(displays[displaysIndex]);
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image]];
        for (CIQRCodeFeature *feature in features) {
            // 解析内容
            NSString *decodeString = [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:feature.messageString options:0] encoding:NSUTF8StringEncoding];
            
//            NSString *ecodeing = [feature.messageString decode]
            if ( [decodeString hasPrefix:@"sp://"] )
            {
                NSString *contentString = [decodeString substringFromIndex:5];
                NSArray *arr = [contentString componentsSeparatedByString:@";"];
                [self.vc.hostLabel setStringValue:arr[0]];
                [self.vc.PortLabel setStringValue:arr[1]];
            }
        }
        CGImageRelease(image);
    }
    
    free(displays);
    
    
}


@end
