//
//  XLFAudioPacketRecorder.m
//  XLFAudioPacketRecorder
//
//  Created by molon on 5/12/14.
//  Copyright (c) 2014 molon. All rights reserved.
//

#import "XLFAudioPacketRecorder.h"
#import <AVFoundation/AVFoundation.h>

@interface XLFAudioPacketRecorder()

@property(nonatomic, strong) NSMutableData *packets;

@property(nonatomic, assign) AudioComponentInstance audioUnit;

@end

@implementation XLFAudioPacketRecorder

- (id)init{
    
    self = [super init];
    if (self) {
        
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

static OSStatus recordCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData){
    XLFAudioPacketRecorder *recorder=(__bridge XLFAudioPacketRecorder *)inRefCon;
    
    NSMutableData *packets = [NSMutableData data];
    UInt32 numberPacket = inNumberFrames * ioData->mNumberBuffers;
    
    for (int i=0; i<ioData->mNumberBuffers; i++) {
        AudioBuffer buffer = ioData->mBuffers[i];
        [packets appendBytes:buffer.mData length:buffer.mDataByteSize];
    }
    
    [recorder addPackets:packets numberPacket:numberPacket];
    
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
                                kAudioUnitScope_Input,
                                1,
                                &flag,
                                sizeof(flag));
    
    AudioStreamBasicDescription audioFormat = [self audioFormat];
    status=AudioUnitSetProperty([self audioUnit],
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Output,
                                1,
                                &audioFormat,
                                sizeof(audioFormat));
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc=recordCallback;
    callbackStruct.inputProcRefCon=(__bridge void *)(self);
    status=AudioUnitSetProperty([self audioUnit],
                                kAudioUnitProperty_SetRenderCallback,
                                kAudioUnitScope_Global,
                                1,
                                &callbackStruct,
                                sizeof(callbackStruct));
    status=AudioUnitInitialize([self audioUnit]);
}

- (void)addPackets:(NSData*)packets numberPacket:(UInt32)numberPacket;{
    
    [[self packets] appendData:packets];
    
    if ([self cacheOverflow] && [[self packets] length] > [self cacheSize]) {
        
        NSInteger overflowSize = [[self packets] length] - [self cacheSize];
        
        overflowSize = (overflowSize / [self bytesPerPacket]) * [self bytesPerPacket];
        
        [[self packets] replaceBytesInRange:NSMakeRange(0, overflowSize) withBytes:NULL];
    }
    
    __weak typeof(self) ws = self;
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        if ([ws delegate] &&
            [[ws delegate] respondsToSelector:@selector(audioPacketRecorder:didRecordPackets:numberPacket:)]) {
            
            [[self delegate] audioPacketRecorder:self didRecordPackets:packets numberPacket:numberPacket];
        }
    });
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
