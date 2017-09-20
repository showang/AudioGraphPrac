//
// Created by William Wang on 2017/9/19.
// Copyright (c) 2017 William Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class MyAudioGraph;

typedef struct RenderCallbackResult {
    AudioUnitRenderActionFlags * _Nonnull ioActionFlags;
    const AudioTimeStamp * _Nonnull inTimeStamp;
    UInt32 inBusNumber;
    UInt32 inNumberFrames;
    AudioBufferList *__nullable ioData;
} RenderCallbackResult;


@interface MyAudioNode : NSObject

- (_Nonnull instancetype)initWithGraph:(MyAudioGraph * _Nonnull)graph;

- (void)connect:(MyAudioNode *_Nonnull)outNode withFormat:(AudioStreamBasicDescription)desc;

- (void)setInputFormat:(AudioStreamBasicDescription)desc;

- (void)setOutputFormat:(AudioStreamBasicDescription)desc;

-(void) renderCallback: (void(^_Nonnull)(RenderCallbackResult)) renderCallbackBlock;

@property(nonatomic) _Nonnull AudioUnit nodeUnit;
@property(weak, nonatomic) MyAudioGraph * _Nullable parentGraph;
@property(nonatomic) NSString * _Nullable name;

@end

@protocol NodeControlInterface

- (void)addToGraph:(MyAudioGraph * _Nonnull)graph;

- (AUNode *_Nonnull)auNodeRef;

- (AudioComponentDescription *_Nonnull)descriptionRef;

@end

@protocol NodeProtectedMethod

- (AudioComponentDescription *_Nonnull)descriptionRef;

@end
