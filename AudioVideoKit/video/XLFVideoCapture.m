//
//  XLFVideoCapture.m
//  XLFAudioVideoKit
//
//  Created by Marike Jave on 15/6/8.
//  Copyright (c) 2015年 Marike Jave. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "XLFVideoCapture.h"

@interface XLFVideoCapture ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property(nonatomic, assign) UIView *contentView;

@property(nonatomic, assign) int64_t framesPerSecond;

@property(nonatomic, strong) AVCaptureSession *session;

@property(nonatomic, assign) id<XLFVideoCaptureDelegate> delegate;

@end

@implementation XLFVideoCapture


- (id)initWithDelegate:(id<XLFVideoCaptureDelegate>)delegate
           contentView:(UIView*)contentView
       framesPerSecond:(int64_t)framesPerSecond;{
    
    self = [self init];
    
    if (self) {
        
        [self setFramesPerSecond:framesPerSecond];
        [self setContentView:contentView];
        [self setDelegate:delegate];
        
        [self setupCaptureSession];
    }
    return self;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // Create a UIImage from the sample buffer data
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);//这里的mData是NSData对象，后面的0.5代表生成的图片质量
    
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(didCaptureFrameImageData:)]) {
        
        [[self delegate] didCaptureFrameImageData:imageData];
    }
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    //UIImage *image = [UIImage imageWithCGImage:quartzImage];
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationRight];
    
    image = [self scaleToSize:[[self contentView] bounds].size inputImage:image];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

- (UIImage *)scaleToSize:(CGSize)size inputImage:(UIImage *)inputImage{
    
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContextWithOptions(size, NO, [inputImage scale]);
    // 绘制改变大小的图片
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    UIEdgeInsets insets = UIEdgeInsetsZero;
    
    // 短边适应 宽度缩小 长度缩小并切割
    if ([inputImage size].width < [inputImage size].height) {
        
        CGFloat scale = size.width/[inputImage size].width;
        insets.top = (size.height - [inputImage size].height * scale) / 2.f;
        insets.bottom = insets.top;
    }
    // 长度放大 宽度放大并切割
    else{
        
        CGFloat scale = size.height/[inputImage size].height;
        insets.left = (size.width - [inputImage size].width * scale) / 2.f;
        insets.right = insets.top;
    }
    
    [inputImage drawInRect:UIEdgeInsetsInsetRect(rect, insets)];
    
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    // 返回新的改变大小后的图片
    return scaledImage;
}


// Create and configure a capture session and start it running
- (void)setupCaptureSession
{
    NSError *error = nil;
    
    // Create the session
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    // Configure the session to produce lower resolution video frames, if your
    // processing algorithm can cope. We'll specify medium quality for the
    // chosen device.
    session.sessionPreset = AVCaptureSessionPresetMedium;
    
    // Find a suitable AVCaptureDevice
    AVCaptureDevice *device = [AVCaptureDevice
                               defaultDeviceWithMediaType:AVMediaTypeVideo];//这里默认是使用后置摄像头，你可以改成前置摄像头
    
    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                        error:&error];
    if (!input) {
        // Handling the error appropriately.
    }
    [session addInput:input];
    
    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [session addOutput:output];
    
    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    
    // Specify the pixel format
    output.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                            [NSNumber numberWithInt: 320], (id)kCVPixelBufferWidthKey,
                            [NSNumber numberWithInt: 240], (id)kCVPixelBufferHeightKey,
                            nil];
    
    if ([self contentView]) {
        AVCaptureVideoPreviewLayer* preLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
        //preLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
        [preLayer setFrame:[[self contentView] bounds]];
        [preLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        [[[self contentView] layer] addSublayer:preLayer];
    }
    // If you wish to cap the frame rate to a known value, such as 15 fps, set
    // minFrameDuration.
    [output setMinFrameDuration:CMTimeMake(1, [self framesPerSecond])];
    
    // Assign session to an ivar.
    [self setSession:session];
}

- (void)start{
    
    [[self session] startRunning];
}

- (void)stop{
    
    [[self session] stopRunning];
}

- (BOOL)isRunning{
    
    return [[self session] isRunning];
}


@end
