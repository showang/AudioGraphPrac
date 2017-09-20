//
// Created by William Wang on 2017/9/19.
// Copyright (c) 2017 William Wang. All rights reserved.
//

#import "MyAudioNode.h"
#import "MyAudioGraph.h"

static OSStatus KKPlayerAURenderCallback(void *userData,
        AudioUnitRenderActionFlags *ioActionFlags,
        const AudioTimeStamp *inTimeStamp,
        UInt32 inBusNumber,
        UInt32 inNumberFrames,
        AudioBufferList *ioData);

@interface MyAudioNode () <NodeControlInterface, NodeProtectedMethod>

@property (nonatomic, copy) void (^renderCallbackBlock)(RenderCallbackResult);
@property (nonatomic) AUNode nodeInstance;

@end

@interface MyAudioGraph () <GraphControlInterface>
@end

@implementation MyAudioNode

- (void)addToGraph:(MyAudioGraph *)graph {
    self.parentGraph = graph;
    OSStatus status = AUGraphAddNode(graph.auGraph, self.descriptionRef, &_nodeInstance);
    AUGraphNodeInfo(graph.auGraph, _nodeInstance, self.descriptionRef, &_nodeUnit);
    NSAssert(noErr == status, @"We need to add the %@. %d", [self name], (int) status);

    UInt32 maxFPS = 4096;
    status = AudioUnitSetProperty(_nodeUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, sizeof(maxFPS));
    NSAssert(noErr == status, @"We need to set the maximum FPS to the %@. %d", [self name], (int) status);
}

- (void)connect:(MyAudioNode *)outNode withFormat:(AudioStreamBasicDescription) desc{
    OSStatus status = AUGraphConnectNodeInput(self.parentGraph.auGraph, _nodeInstance, 0, *outNode.auNodeRef, 0);
    [self setOutputFormat:desc];
    [outNode setInputFormat:desc];
    NSAssert(noErr == status, @"We need to connect the nodes within the audio graph. %d", (int) status);
}

- (void)setInputFormat:(AudioStreamBasicDescription) desc{
    OSStatus status = AudioUnitSetProperty(_nodeUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &desc, sizeof(desc));
    NSAssert(noErr == status, @"We need to set input format of the %@. %d", [self name], (int) status);
}

- (void) setOutputFormat:(AudioStreamBasicDescription) desc{
    OSStatus status = AudioUnitSetProperty(_nodeUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &desc, sizeof(desc));
    NSAssert(noErr == status, @"We need to set output format of the %@. %d", [self name], (int) status);
}

- (AUNode *)auNodeRef {
    return &_nodeInstance;
}

- (AUNode)auNodeInstance {
    return _nodeInstance;
}

- (void)renderCallback:(void (^)(RenderCallbackResult))renderCallbackBlock {
    self.renderCallbackBlock = renderCallbackBlock;
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProcRefCon = (__bridge void *) (self);
    callbackStruct.inputProc = KKPlayerAURenderCallback;
    OSStatus status = AUGraphSetNodeInputCallback(self.parentGraph.auGraph, [self auNodeInstance], 0, &callbackStruct);
    NSAssert(noErr == status, @"Must be no error.");
}

- (void) onRenderCallback:(RenderCallbackResult) result{
    self.renderCallbackBlock(result);
}

- (instancetype)initWithGraph:(MyAudioGraph *)graph {
    // Template Method由 Child 實作
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AudioComponentDescription *)descriptionRef {
    // Template Method由 Child 實作
    [self doesNotRecognizeSelector:_cmd];
    return NULL;
}

@end

OSStatus KKPlayerAURenderCallback(void *userData,
        AudioUnitRenderActionFlags *ioActionFlags,
        const AudioTimeStamp *inTimeStamp,
        UInt32 inBusNumber,
        UInt32 inNumberFrames,
        AudioBufferList *ioData) {
    MyAudioNode *self = (__bridge MyAudioNode *) userData;
    RenderCallbackResult result;
    result.ioActionFlags = ioActionFlags;
    result.inTimeStamp = inTimeStamp;
    result.inBusNumber = inBusNumber;
    result.inNumberFrames = inNumberFrames;
    result.ioData = ioData;
    [self onRenderCallback:result];
    return noErr;
}