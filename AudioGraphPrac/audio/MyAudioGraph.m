//
// Created by William Wang on 2017/9/19.
// Copyright (c) 2017 William Wang. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "MyAudioGraph.h"
#import "MyAudioNode.h"

@interface MyAudioGraph() <GraphControlInterface>
{
    AUGraph audioGraph;
}
@end
@interface MyAudioNode()<NodeControlInterface>
@end

@implementation MyAudioGraph

- (instancetype)init {
    self = [super init];
    if(self){
        OSStatus status = NewAUGraph(&audioGraph);
        NSAssert(noErr == status, @"We need to create a new audio graph. %d", (int) status);
        status = AUGraphOpen(audioGraph);
        NSAssert(noErr == status, @"We need to open the audio graph. %d", (int) status);
    }
    return self;
}

- (void)addNode:(MyAudioNode *)node {
    [node addToGraph:self];
}

- (void)initialize {
    OSStatus status = AUGraphInitialize(audioGraph);
    NSAssert(noErr == status, @"Must be no error.");
}


- (AUGraph)auGraph {
    return audioGraph;
}

- (void)finish {
    AUGraphUninitialize(audioGraph);
    AUGraphClose(audioGraph);
    DisposeAUGraph(audioGraph);
}

- (void)showStatus {
    CAShow(audioGraph);
}

@end