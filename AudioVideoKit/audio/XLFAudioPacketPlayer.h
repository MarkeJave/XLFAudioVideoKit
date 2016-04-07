//
//  XLFAudioPacketPlayer.h
//  XLFAudioPacketPlayer
//
//  Created by molon on 5/12/14.
//  Copyright (c) 2014 molon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "XLFAudioMeterObserver.h"

@interface XLFAudioPacketPlayer : NSObject<XLFAudioMeterObserverDataSource>

- (void)addPackets:(NSData*)packets;

@property(nonatomic, assign) AudioComponentInstance audioUnit;

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


-(OSStatus)start;
-(OSStatus)stop;
-(void)cleanup;
-(void)initaliseAudio;

@end
