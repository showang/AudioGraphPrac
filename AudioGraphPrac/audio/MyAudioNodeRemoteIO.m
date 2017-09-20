//
// Created by William Wang on 2017/9/19.
// Copyright (c) 2017 William Wang. All rights reserved.
//

#import "MyAudioNodeRemoteIO.h"
#import "MyAudioGraph.h"

@interface MyAudioNodeRemoteIO () <NodeProtectedMethod> {
    AudioComponentDescription desc;
}
@end

@implementation MyAudioNodeRemoteIO

- (instancetype)initWithGraph:(MyAudioGraph *)graph {
    self = [self init];
    if(self){
        [graph addNode:self];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.name = @"RemoteIONode";
        bzero(&desc, sizeof(AudioComponentDescription));
        desc.componentType = kAudioUnitType_Output;
        desc.componentSubType = kAudioUnitSubType_RemoteIO;
        desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        desc.componentFlags = 0;
        desc.componentFlagsMask = 0;
    }
    return self;
}

- (AudioComponentDescription *)descriptionRef {
    return &desc;
}

- (void)startOutput{
    OSStatus status = AUGraphStart(self.parentGraph.auGraph);
    NSAssert(noErr == status, @"AUGraphStart, error: %ld", (signed long) status);
    status = AudioOutputUnitStart(self.nodeUnit);
    NSAssert(noErr == status, @"AudioOutputUnitStart, error: %ld", (signed long) status);
}

- (void)stopOutput{
    OSStatus status = AUGraphStop(self.parentGraph.auGraph);
    NSAssert(noErr == status, @"AUGraphStart, error: %ld", (signed long) status);
    status = AudioOutputUnitStop(self.nodeUnit);
    NSAssert(noErr == status, @"AudioOutputUnitStop, error: %ld", (signed long) status);
}

@end