//
//  XLFAudioPacketRecorder.h
//  XLFAudioPacketRecorder
//
//  Created by molon on 5/12/14.
//  Copyright (c) 2014 molon. All rights reserved.
//

/**
 *  使用audioqueque来实时录音，边录音边转码，可以设置自己的转码方式。从PCM数据转
 */

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class XLFAudioPacketRecorder;

@protocol XLFAudioPacketRecorderDelegate <NSObject>

- (void)audioPacketRecorder:(XLFAudioPacketRecorder *)audioPacketRecorder didRecordPackets:(NSData*)packets numberPacket:(UInt32)numberPacket;

@end

@interface XLFAudioPacketRecorder : NSObject

@property(nonatomic, assign) Float64             sampleRate;

@property(nonatomic, assign) AudioFormatID       formatID;

@property(nonatomic, assign) AudioFormatFlags    formatFlags;

@property(nonatomic, assign) UInt32              bytesPerPacket;

@property(nonatomic, assign) UInt32              framesPerPacket;

@property(nonatomic, assign) UInt32              bytesPerFrame;

@property(nonatomic, assign) UInt32              channelsPerFrame;

@property(nonatomic, assign) UInt32              bitsPerChannel;

@property(nonatomic, assign) BOOL                cacheOverflow;

@property(nonatomic, assign) NSUInteger          cacheSize; // if cacheOverflow is NO, cacheSize is useless.

@property(nonatomic, assign) id<XLFAudioPacketRecorderDelegate> delegate;

-(OSStatus)start;
-(OSStatus)stop;
-(void)cleanup;
-(void)initaliseAudio;

@end
