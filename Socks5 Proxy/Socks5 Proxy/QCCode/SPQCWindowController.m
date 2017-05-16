//
//  SPQCWindowController.m
//  Socks5 Proxy
//
//  Created by zkhCreator on 15/05/2017.
//  Copyright © 2017 zkhCreator. All rights reserved.
//

#import "SPQCWindowController.h"
#import <CoreImage/CoreImage.h>

@interface SPQCWindowController ()
@property (weak) IBOutlet NSImageView *QCCodeImageView;
@property (nonatomic, copy) NSString *contentMessage;

@end

@implementation SPQCWindowController

- (instancetype)initWithMessage:(NSString *)message {
    if (!message) {
        return nil;
    }
    
    self = [super initWithWindowNibName:@"SPQCWindowController"];
    if (self) {
        _contentMessage = message;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    _QCCodeImageView.image = [[NSImage alloc] initWithCGImage:[self createQRImageForString:_contentMessage size:CGSizeMake(250.f, 250.f)] size:CGSizeMake(250.f, 250.f)];
    
}


- (CGImageRef)createQRImageForString:(NSString *)string size:(CGSize)size {
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [filter setValue:data forKey:@"inputMessage"];
    CIImage *image = [filter valueForKey:@"outputImage"];
    
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size.width / CGRectGetWidth(extent), size.height / CGRectGetHeight(extent));
    
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    
#if TARGET_OS_IPHONE
    CIContext *context = [CIContext contextWithOptions:nil];
#else
    CIContext *context = [CIContext contextWithCGContext:bitmapRef options:nil];
#endif
    
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);

    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    
    return scaledImage;
}


- (IBAction)copyQCImage:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    
    // 删除已有的内容，防止干扰
    [pasteboard clearContents];
    [pasteboard writeObjects:@[_QCCodeImageView.image]];
    
}

@end
