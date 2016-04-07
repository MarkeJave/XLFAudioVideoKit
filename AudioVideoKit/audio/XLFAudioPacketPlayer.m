//
//  XLFAudioPacketPlayer.m
//  XLFAudioPacketPlayer
//
//  Created by molon on 5/12/14.
//  Copyright (c) 2014 molon. All rights reserved.
//

#import "XLFAudioPacketPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface XLFAudioPacketPlayer()

@property(nonatomic, strong) NSMutableData *packets;

@property(nonatomic, assign) NSUInteger packetReadOffset;

@end

@implementation XLFAudioPacketPlayer

- (id)init{
    
    self = [super init];
    if (self) {
        
        [self setCacheSize:1024*1024*10];   // 10MB
    }
    return self;
}

- (void)dealloc{
    
    [self stop];
}

-(OSStatus)start{
    OSStatus status=AudioOutputUnitStart([self audioUnit]);
    return status;
}


-(OSStatus)stop{
    OSStatus status=AudioOutputUnitStop([self audioUnit]);
    return  status;
}

-(void)cleanup{
    AudioUnitUninitialize([self audioUnit]);
}

- (void)addPackets:(NSData*)packets{
    
    [[self packets] appendData:packets];
    
    if ([self cacheOverflow] && [[self packets] length] > [self cacheSize]) {
        
        NSInteger overflowSize = [[self packets] length] - [self cacheSize];
        
        overflowSize = (overflowSize / [self bytesPerPacket]) * [self bytesPerPacket];
        
        [[self packets] replaceBytesInRange:NSMakeRange(0, overflowSize) withBytes:NULL];
    }
}

static OSStatus playCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData){
    
    XLFAudioPacketPlayer *player=(__bridge XLFAudioPacketPlayer *)inRefCon;
    
    for (int i=0; i<ioData->mNumberBuffers; i++) {
        
        AudioBuffer buffer=ioData->mBuffers[i];
        
        void *frameBuffer=buffer.mData;
        void *packet = malloc(buffer.mDataByteSize);
        
        [player nextPacket:packet packetSize:buffer.mDataByteSize];
        
        memcpy(frameBuffer, packet, buffer.mDataByteSize);
        
        free(packet);
    }
    return noErr;
}

-(void)initaliseAudio{
    OSStatus status;
    
    AudioComponentDescription desc;
    desc.componentType=kAudioUnitType_Output;
    desc.componentSubType=kAudioUnitSubType_RemoteIO;
    desc.componentFlags=0;
    desc.componentFlagsMask=0;
    desc.componentManufacturer=kAudioUnitManufacturer_Apple;
    
    AudioComponent inputComponent=AudioComponentFindNext(NULL, &desc);
    
    status=AudioComponentInstanceNew(inputComponent, &_audioUnit);
    
    UInt32 flag=1;
    
    status=AudioUnitSetProperty(_audioUnit,
                                kAudioOutputUnitProperty_EnableIO,
                                kAudioUnitScope_Output,
                                0,
                                &flag,
                                sizeof(flag));
    
    AudioStreamBasicDescription audioFormat = [self audioFormat];
    
    status=AudioUnitSetProperty([self audioUnit],
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &audioFormat,
                                sizeof(audioFormat));
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc=playCallback;
    callbackStruct.inputProcRefCon=(__bridge void *)(self);
    status=AudioUnitSetProperty([self audioUnit],
                                kAudioUnitProperty_SetRenderCallback,
                                kAudioUnitScope_Global,
                                0,
                                &callbackStruct,
                                sizeof(callbackStruct));
    status=AudioUnitInitialize([self audioUnit]);
}

- (void)nextPacket:(void *)buffer packetSize:(NSUInteger)packetSize;{
    
    memcpy(buffer, [[self packets] bytes] + [self packetReadOffset], packetSize);
    
    self.packetReadOffset += packetSize;
}

- (AudioStreamBasicDescription)audioFormat;{
    
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate=[self sampleRate];
    audioFormat.mFormatID=[self formatID];
    audioFormat.mFormatFlags=[self formatFlags];
    audioFormat.mFramesPerPacket=[self framesPerPacket];
    audioFormat.mChannelsPerFrame=[self channelsPerFrame];
    audioFormat.mBitsPerChannel=[self bitsPerChannel];
    audioFormat.mBytesPerPacket=[self bytesPerPacket];
    audioFormat.mBytesPerFrame=[self bytesPerFrame];
    
    return audioFormat;
}

- (AudioStreamBasicDescription)defualtAudioFormat;{
    
    AudioStreamBasicDescription audioFormat;
    
    audioFormat.mSampleRate=44100;
    audioFormat.mFormatID=kAudioFormatLinearPCM;
    audioFormat.mFormatFlags=kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket=1;
    audioFormat.mChannelsPerFrame=2;
    audioFormat.mBitsPerChannel=16;
    audioFormat.mBytesPerPacket=4;
    audioFormat.mBytesPerFrame=4;
    
    return audioFormat;
}


@end
