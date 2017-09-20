//
// Created by William Wang on 2017/9/19.
// Copyright (c) 2017 William Wang. All rights reserved.
//

#import "MyAudioNodeMixer.h"
#import "MyAudioGraph.h"



@interface MyAudioNodeMixer() <NodeProtectedMethod>{
    AudioComponentDescription desc;
}


@end

@implementation MyAudioNodeMixer

- (instancetype)initWithGraph:(MyAudioGraph *)graph {
    self = [self init];
    if(self){
        [graph addNode:self];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if(self){
        self.name = @"MixerNode";
        desc.componentType = kAudioUnitType_Mixer;
        desc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
        desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        desc.componentFlags = 0;
        desc.componentFlagsMask = 0;
    }
    return self;
}

- (AudioComponentDescription*) descriptionRef{
    return &desc;
}



@end

