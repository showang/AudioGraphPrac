//
// Created by William Wang on 2017/9/19.
// Copyright (c) 2017 William Wang. All rights reserved.
//

#import "MyAudioNodeEQ.h"
#import "MyAudioGraph.h"

@interface MyAudioNodeEQ() <NodeProtectedMethod>{
    AudioComponentDescription desc;
}
@end

@implementation MyAudioNodeEQ

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
        self.name = @"EQNode";
        desc.componentType = kAudioUnitType_Effect;
        desc.componentSubType = kAudioUnitSubType_AUiPodEQ;
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