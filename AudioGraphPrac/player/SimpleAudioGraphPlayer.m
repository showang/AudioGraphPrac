//
//  SimpleAudioGraphPlayer.m
//  MihPracSwift
//
//  Created by William Wang on 2017/9/14.
//  Copyright © 2017年 William Wang. All rights reserved.
//

#import "SimpleAudioGraphPlayer.h"
#import "MyAudioParser.h"
#import "MyAudioGraph.h"
#import "MyAudioNodeMixer.h"
#import "MyAudioNodeEQ.h"
#import "MyAudioNodeRemoteIO.h"
#import <AVFoundation/AVFoundation.h>

static OSStatus KKPlayerConverterFiller(AudioConverterRef inAudioConverter,
        UInt32 *ioNumberDataPackets,
        AudioBufferList *ioData,
        AudioStreamPacketDescription **outDataPacketDescription,
        void *inUserData);

static const OSStatus KKAudioConverterCallbackErr_NoData = 'kknd';

static AudioStreamBasicDescription KKSignedIntLinearPCMStreamDescription();

@interface SimpleAudioGraphPlayer () <NSURLSessionDataDelegate> {
    AudioStreamBasicDescription streamDescription;
    AudioBufferList *renderBufferList;
    UInt32 renderBufferSize;
    size_t readHead;
}

@property(nonatomic) PlayerState state;
@property(nonatomic) NSString *currentUrlString;
@property(nonatomic) NSURLSessionDataTask *task;

@property(nonatomic) MyAudioParser *myMp3PacketParser;
@property(nonatomic) NSMutableArray *packets;

@property(nonatomic) MyAudioGraph *graph;
@property(nonatomic) MyAudioNodeMixer *myMixerNode;
@property(nonatomic) MyAudioNodeEQ *myEQNode;
@property(nonatomic) MyAudioNodeRemoteIO *myRemoteIoNode;

@end

@implementation SimpleAudioGraphPlayer

- (id)init {
    self = [super init];
    if (self) {
        [self buildOutputUnit];
        self.state = STOP;
    }
    return self;
}

- (instancetype)initWithDelegate:(id <SimpleAudioGraphPlayerDelegate>)delegate {
    self = [self init];
    self.delegate = delegate;
    [self updatePlayerState:STOP];
    return self;
}

- (void)dealloc {
    [self stop];
    [self.myMp3PacketParser close];
    [self.graph finish];
    [self.task cancel];
    free(renderBufferList->mBuffers[0].mData);
    free(renderBufferList);
    renderBufferList = NULL;

}

- (void)buildOutputUnit {

    self.graph = [[MyAudioGraph alloc] init];

    self.myMixerNode = [[MyAudioNodeMixer alloc] initWithGraph:self.graph];
    self.myEQNode = [[MyAudioNodeEQ alloc] initWithGraph:self.graph];
    self.myRemoteIoNode = [[MyAudioNodeRemoteIO alloc] initWithGraph:self.graph];

    AudioStreamBasicDescription audioFormat = KKSignedIntLinearPCMStreamDescription();
    [self.myMixerNode setInputFormat:audioFormat];
    [self.myMixerNode connect:self.myEQNode withFormat:audioFormat];
    [self.myEQNode connect:self.myRemoteIoNode withFormat:audioFormat];

    __weak SimpleAudioGraphPlayer *weakSelf = self;
    [self.myMixerNode renderCallback:^(RenderCallbackResult result) {
        OSStatus callbackStatus = [weakSelf callbackWithNumberOfFrames:result.inNumberFrames
                                                                ioData:result.ioData busNumber:result.inBusNumber];
        if (callbackStatus != noErr) {
            result.ioData->mNumberBuffers = 0;
            *result.ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
        }
    }];

    [self.graph initialize];
    [self.graph showStatus];

    //  建立 converter 要使用的 buffer list
    UInt32 bufferSize = 4096 * 4;
    renderBufferSize = bufferSize;
    renderBufferList = (AudioBufferList *) calloc(1, sizeof(UInt32) + sizeof(AudioBuffer));
    renderBufferList->mNumberBuffers = 1;
    renderBufferList->mBuffers[0].mNumberChannels = 2;
    renderBufferList->mBuffers[0].mDataByteSize = bufferSize;
    renderBufferList->mBuffers[0].mData = calloc(1, bufferSize);
}

- (void)startWithUrl:(NSString *)url {
    if (self.currentUrlString && [self.currentUrlString isEqualToString:url] && self.packets && [self.packets count] != 0) {
        [self play];
        return;
    }
    if (self.myMp3PacketParser) {
        [self.myMp3PacketParser close];
    }
    self.currentUrlString = url;
    self.packets = [[NSMutableArray alloc] init];
    self.myMp3PacketParser = [[MyAudioParser alloc]
            initWithOutputStreamDescription:KKSignedIntLinearPCMStreamDescription()
                                  audioType:kAudioFileMP3Type];
    [self.myMp3PacketParser open];
    NSURL *inURL = [[NSURL alloc] initWithString:url];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    self.task = [session dataTaskWithRequest:[NSURLRequest requestWithURL:inURL]];
    [self updatePlayerState:BUFFERING];
    [self.task resume];
}

- (double)packetsPerSecond {
    if (streamDescription.mFramesPerPacket) {
        return streamDescription.mSampleRate / streamDescription.mFramesPerPacket;
    }
    return 44100.0 / 1152.0;
}

- (void)play {
    if (self.state != PAUSE && self.state != STOP) {
        return;
    }
    [self updatePlayerState:PLAYING];
    NSError *audioSessionError;
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:&audioSessionError];
    [AVAudioSession.sharedInstance setActive:YES error:&audioSessionError];

    [self.myRemoteIoNode startOutput];
}

- (void)pause {
    if (self.state != PLAYING) {
        return;
    }
    [self updatePlayerState:PAUSE];
    [self.myRemoteIoNode stopOutput];
}

- (void)stop {
    [self updatePlayerState:STOP];
    [self.myRemoteIoNode stopOutput];
    readHead = 0;
}

- (void)updatePlayerState:(PlayerState)state {
    self.state = state;
    __weak SimpleAudioGraphPlayer *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.delegate SimpleAudioGraphPlayer:weakSelf updateWith:state];
    });
}

- (CFArrayRef)iPodEQPresetsArray {
    CFArrayRef array;
    UInt32 size = sizeof(array);
    AudioUnitGetProperty(self.myEQNode.nodeUnit, kAudioUnitProperty_FactoryPresets, kAudioUnitScope_Global, 0, &array, &size);
    return array;
}

- (void)selectEQPreset:(NSInteger)value {
    AUPreset *aPreset = (AUPreset *) CFArrayGetValueAtIndex(self.iPodEQPresetsArray, value);
    AudioUnitSetProperty(self.myEQNode.nodeUnit, kAudioUnitProperty_PresentPreset, kAudioUnitScope_Global, 0, aPreset, sizeof(AUPreset));
}

#pragma mark -
#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    NSLog(@"didBecomeInvalidWithError");
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    __weak SimpleAudioGraphPlayer *weakSelf = self;
    [self.myMp3PacketParser parsePacketData:data complete:^(NSArray<NSData *> *packetArray) {
        [weakSelf.packets addObjectsFromArray:packetArray];
        if (readHead == 0 && [weakSelf.packets count] > (int) ([weakSelf packetsPerSecond] * 3)) {
            if (self.state == BUFFERING) {
                self.state = PAUSE;
                [self play];
            }
        }
    }];
}

- (void)  URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (error) {
        NSLog(@"Failed to load data: %@", [error localizedDescription]);
        [self stop];
        return;
    }
    NSLog(@"Complete loading data");
}

#pragma mark -
#pragma mark Properties

- (OSStatus)callbackWithNumberOfFrames:(UInt32)inNumberOfFrames
                                ioData:(AudioBufferList *)inIoData busNumber:(UInt32)inBusNumber {
    @synchronized (self) {
        if (readHead < [self.packets count]) {
            @autoreleasepool {
                UInt32 packetSize = inNumberOfFrames;
                OSStatus status =
                        AudioConverterFillComplexBuffer(self.myMp3PacketParser.converter,
                                KKPlayerConverterFiller,
                                (__bridge void *) (self),
                                &packetSize, renderBufferList, NULL);
                if (noErr != status && KKAudioConverterCallbackErr_NoData != status) {
                    [self pause];
                    return -1;
                } else if (!packetSize) {
                    inIoData->mNumberBuffers = 0;
                } else {
                    inIoData->mNumberBuffers = 1;
                    inIoData->mBuffers[0].mNumberChannels = 2;
                    inIoData->mBuffers[0].mDataByteSize = renderBufferList->mBuffers[0].mDataByteSize;
                    inIoData->mBuffers[0].mData = renderBufferList->mBuffers[0].mData;
                    renderBufferList->mBuffers[0].mDataByteSize = renderBufferSize;
                }
            }
        } else {
            inIoData->mNumberBuffers = 0;
            return -1;
        }
    }

    return noErr;
}


- (OSStatus)_fillConverterBufferWithBufferlist:(AudioBufferList *)ioData
                             packetDescription:(AudioStreamPacketDescription **)outDataPacketDescription {
    static AudioStreamPacketDescription aspdesc;

    if (readHead >= [self.packets count]) {
        return KKAudioConverterCallbackErr_NoData;
    }

    ioData->mNumberBuffers = 1;
    NSData *packet = self.packets[readHead];
    void const *data = [packet bytes];
    UInt32 length = (UInt32) [packet length];
    ioData->mBuffers[0].mData = (void *) data;
    ioData->mBuffers[0].mDataByteSize = length;

    *outDataPacketDescription = &aspdesc;
    aspdesc.mDataByteSize = length;
    aspdesc.mStartOffset = 0;
    aspdesc.mVariableFramesInPacket = 1;

    readHead++;
    return 0;
}

@end

OSStatus KKPlayerConverterFiller(AudioConverterRef inAudioConverter,
        UInt32 *ioNumberDataPackets,
        AudioBufferList *ioData,
        AudioStreamPacketDescription **outDataPacketDescription,
        void *inUserData) {
    // 第八步： AudioConverterFillComplexBuffer 的 callback
    SimpleAudioGraphPlayer *self = (__bridge SimpleAudioGraphPlayer *) inUserData;
    *ioNumberDataPackets = 0;
    OSStatus result = [self _fillConverterBufferWithBufferlist:ioData
                                             packetDescription:outDataPacketDescription];
    if (result == noErr) {
        *ioNumberDataPackets = 1;
    }
    return result;
}

AudioStreamBasicDescription KKSignedIntLinearPCMStreamDescription() {
    AudioStreamBasicDescription destFormat;
    bzero(&destFormat, sizeof(AudioStreamBasicDescription));
    destFormat.mSampleRate = 44100.0;
    destFormat.mFormatID = kAudioFormatLinearPCM;
    destFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
    destFormat.mFramesPerPacket = 1;
    destFormat.mBytesPerPacket = 4;
    destFormat.mBytesPerFrame = 4;
    destFormat.mChannelsPerFrame = 2;
    destFormat.mBitsPerChannel = 16;
    destFormat.mReserved = 0;
    return destFormat;
}
