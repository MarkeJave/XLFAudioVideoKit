//
//  XLFAudioQueueRecorder.h
//  XLFAudioQueueRecorder
//
//  Created by molon on 5/12/14.
//  Copyright (c) 2014 molon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

/**
 *  缓存区的个数，一般3个
 */
extern const NSInteger kNumberAudioQueueBuffers;

/**
 *  采样率，要转码为amr的话必须为8000
 */
extern const NSInteger kDefaultSampleRate;

extern const NSInteger kDefaultInputBufferSize;

@class XLFAudioQueueRecorder;

@protocol XLFAudioQueueRecorderDelegate <NSObject>

@optional
/**
 *  录音遇到了错误。
 */
- (void)didRecordError:(NSError *)error;

/**
 *  录音被停止
 *  一般是在writer delegate中因为一些状况意外停止录音获得此事件时候使用，参考XLFAmrRecordWriter里实现。
 */
- (void)didRecordStopped;

- (void)audioQueueRecorder:(XLFAudioQueueRecorder *)audioQueueRecorder didRecord:(NSData*)data startTime:(const AudioTimeStamp *)startTime numPackets:(UInt32)numPackets packetDesc:(const AudioStreamPacketDescription *)packetDesc;

@end

@interface XLFAudioQueueRecorder : NSObject
{
    @public
    //音频输入队列
    AudioQueueRef				_recordQueue;
    //音频输入数据format
    AudioStreamBasicDescription	_recordFormat;
}


@property AudioQueueRef	recordQueue;
@property AudioStreamBasicDescription recordFormat;

/**
 *  是否正在录音
 */
@property (atomic, assign,readonly) BOOL isRecording;

/**
 *  参考XLFAudioQueueRecorderDelegate
 */
@property (nonatomic, assign) id<XLFAudioQueueRecorderDelegate> delegate;

- (void)start;
- (void)stop;


@end
