//
//  XLFVideoCapture.h
//  XLFAudioVideoKit
//
//  Created by Marike Jave on 15/6/8.
//  Copyright (c) 2015年 Marike Jave. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XLFVideoCaptureDelegate <NSObject>

- (void)didCaptureFrameImageData:(NSData*)frameImageData;

@end

@interface XLFVideoCapture : NSObject

@property(nonatomic, assign, readonly) UIView *contentView;

@property(nonatomic, assign, readonly) int64_t framesPerSecond;

@property(nonatomic, assign, readonly) BOOL isRunning;

@property(nonatomic, assign, readonly) id<XLFVideoCaptureDelegate> delegate;

//@property(nonatomic, assign) CGSize captureSize;

- (id)initWithDelegate:(id<XLFVideoCaptureDelegate>)delegate
           contentView:(UIView*)contentView
       framesPerSecond:(int64_t)framesPerSecond;

- (void)start;

- (void)stop;

@end
