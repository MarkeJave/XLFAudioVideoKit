//
//  XLFAudioMeterObserver.m
//  XLFAudioQueueRecorderKit
//
//  Created by molon on 5/13/14.
//  Copyright (c) 2014 molon. All rights reserved.
//

#import "XLFAudioMeterObserver.h"

#define kDefaultRefreshInterval 0.1 //默认0.1秒刷新一次
#define kXLFAudioMeterObserverErrorDomain @"XLFAudioMeterObserverErrorDomain"

#define IfAudioQueueErrorPostAndReturn(operation,error) \
if(operation!=noErr) { \
[self postAErrorWithErrorCode:XLFAudioMeterObserverErrorCodeAboutQueue andDescription:error]; \
return; \
}   \

@interface XLFAudioMeterObserver()

@property (nonatomic, strong) NSTimer *timer;

@end


@implementation XLFAudioMeterObserver

- (instancetype)init {

    self = [super init];
    if (self) {
        //这里默认用_设置下吧。免得直接初始化了timer
        _refreshInterval = kDefaultRefreshInterval;
    }
    return self;
}

- (void)dealloc{

    [self.timer invalidate];
    self.timer = nil;
    
	NSLog(@"XLFAudioMeterObserver dealloc");
}

#pragma mark - setter and getter
- (void)setRefreshInterval:(NSTimeInterval)refreshInterval {

    _refreshInterval = refreshInterval;
    
    //重置timer
    [self.timer invalidate];
    self.timer = [NSTimer
                  scheduledTimerWithTimeInterval:refreshInterval
                  target:self
                  selector:@selector(refresh)
                  userInfo:nil
                  repeats:YES
                  ];
}

- (void)setDataSource:(id<XLFAudioMeterObserverDataSource>)dataSource{
    
    if (_dataSource != dataSource) {
        
        _dataSource = dataSource;
        
        [self configObsever];
    }
}

- (void)configObsever;{
    //处理关闭定时器
    [self.timer invalidate];
    self.timer = nil;
    
    if ([self dataSource]) {
        
        //重新设置timer
        self.timer = [NSTimer
                      scheduledTimerWithTimeInterval:self.refreshInterval
                      target:self
                      selector:@selector(refresh)
                      userInfo:nil
                      repeats:YES
                      ];
    }
    //检测这玩意是否支持光谱图
//    UInt32 val = 1;
//    IfAudioQueueErrorPostAndReturn(AudioQueueSetProperty(audioQueue, kAudioQueueProperty_EnableLevelMetering, &val, sizeof(UInt32)), @"couldn't enable metering");
//    
//    if (!val){
//        NSLog(@"不支持光谱图"); //需要发送错误
//        return;
//    }
}

- (void)refresh {
   
    IfAudioQueueErrorPostAndReturn(AudioUnitGetParameter([[self dataSource] audioUnit], kAudioUnitParameterUnit_Meters, kAudioUnitProperty_MeteringMode, 0, &_levelMeterState),@"获取meter数据失败");
    
    if(self.actionBlock){
        self.actionBlock([self levelMeterState],self);
    }
}


- (void)postAErrorWithErrorCode:(XLFAudioMeterObserverErrorCode)code andDescription:(NSString*)description {

    NSLog(@"监控音频队列光谱发生错误");
    
    NSError *error = [NSError errorWithDomain:kXLFAudioMeterObserverErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:description}];
    
    if( self.errorBlock){
        self.errorBlock(error,self);
    }
}

+ (Float32)volumeForLevelMeterStates:(Float32)levelMeterState {

    //获取音量百分比，姑且这么叫吧
    Float32 volume = pow(10, (0.05 * levelMeterState));

    return volume;
}

@end
