//
//  XLFAudioMeterObserver.h
//  XLFAudioQueueRecorderKit
//
//  Created by molon on 5/13/14.
//  Copyright (c) 2014 molon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class XLFAudioMeterObserver;

typedef void (^XLFAudioMeterObserverActionBlock)(Float32 levelMeterStates,XLFAudioMeterObserver *meterObserver);
typedef void (^XLFAudioMeterObserverErrorBlock)(NSError *error,XLFAudioMeterObserver *meterObserver);

/**
 *  错误标识
 */
typedef NS_OPTIONS(NSUInteger, XLFAudioMeterObserverErrorCode) {
    XLFAudioMeterObserverErrorCodeAboutQueue, //关于音频输入队列的错误
};

@protocol XLFAudioMeterObserverDataSource <NSObject>

@property(nonatomic, assign) AudioComponentInstance audioUnit;
@property(nonatomic, assign) UInt32                 channelsPerFrame;  

@end

@interface XLFAudioMeterObserver : NSObject

@property (nonatomic, assign) Float32 levelMeterState;

@property (nonatomic, copy) XLFAudioMeterObserverActionBlock actionBlock;

@property (nonatomic, copy) XLFAudioMeterObserverErrorBlock errorBlock;

@property (nonatomic, assign) NSTimeInterval refreshInterval; //刷新间隔,默认0.1

@property (nonatomic, assign) id<XLFAudioMeterObserverDataSource> dataSource;

/**
 *  根据meterStates计算出音量，音量为 0-1
 *
 */
+ (Float32)volumeForLevelMeterStates:(Float32)levelMeterStates;

@end
