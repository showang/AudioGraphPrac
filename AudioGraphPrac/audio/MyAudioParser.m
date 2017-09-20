//
// Created by William Wang on 2017/9/18.
// Copyright (c) 2017 William Wang. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "MyAudioParser.h"

@interface MyAudioParser () {
    AudioFileStreamID audioFileStreamID;
    AudioConverterRef converter;
    AudioStreamBasicDescription outFormat;
}

@property(nonatomic, copy) void (^parseCallback)(NSArray<NSData *> *);
@property(nonatomic) AudioFileTypeID audioFileTypeID;

@end

static void KKAudioFileStreamPropertyListener(void *inClientData,
        AudioFileStreamID inAudioFileStream,
        AudioFileStreamPropertyID inPropertyID,
        AudioFileStreamPropertyFlags *ioFlags);

static void KKAudioFileStreamPacketsCallback(void *inClientData,
        UInt32 inNumberBytes,
        UInt32 inNumberPackets,
        const void *inInputData,
        AudioStreamPacketDescription *inPacketDescriptions);


@implementation MyAudioParser

- (instancetype)initWithOutputStreamDescription:(AudioStreamBasicDescription)description audioType:(AudioFileTypeID)typeId {
    self = [super init];
    if (self) {
        outFormat = description;
        self.audioFileTypeID = typeId;
    }
    return self;
}

- (void)open {
    AudioFileStreamOpen((__bridge void *) (self),
            KKAudioFileStreamPropertyListener,
            KKAudioFileStreamPacketsCallback,
            self.audioFileTypeID, &audioFileStreamID);
}

- (void)close {
    AudioFileStreamClose(audioFileStreamID);
    AudioConverterDispose(converter);
}

- (void)parsePacketData:(NSData *)data complete:(void (^)(NSArray<NSData *> *))parsedPackets {
    self.parseCallback = parsedPackets;
    AudioFileStreamParseBytes(audioFileStreamID, (UInt32) [data length], [data bytes], 0);
}

- (void)parseDataComplete:(NSMutableArray *)packets {
    self.parseCallback(packets);
}

- (AudioConverterRef)converter {
    return converter;
}

- (void)createConverter:(AudioStreamBasicDescription *)audioStreamBasicDescription {
    AudioConverterNew(audioStreamBasicDescription, &outFormat, &converter);
}

@end

void KKAudioFileStreamPropertyListener(void *inClientData,
        AudioFileStreamID inAudioFileStream,
        AudioFileStreamPropertyID inPropertyID,
        AudioFileStreamPropertyFlags *ioFlags) {
    MyAudioParser *self = (__bridge MyAudioParser *) inClientData;
    if (inPropertyID == kAudioFileStreamProperty_DataFormat) {
        UInt32 dataSize = 0;
        OSStatus status = 0;
        AudioStreamBasicDescription audioStreamDescription;
        Boolean writable = false;
        status = AudioFileStreamGetPropertyInfo(inAudioFileStream,
                kAudioFileStreamProperty_DataFormat, &dataSize, &writable);
        if(status){
            NSLog(@"some error in AudioFileStreamGetPropertyInfo");
        }
        status = AudioFileStreamGetProperty(inAudioFileStream,
                kAudioFileStreamProperty_DataFormat, &dataSize, &audioStreamDescription);
        if(status){
            NSLog(@"some error in AudioFileStreamGetProperty");
        }
        NSLog(@"mSampleRate: %f", audioStreamDescription.mSampleRate);
        NSLog(@"mFormatID: %u", (unsigned int) audioStreamDescription.mFormatID);
        NSLog(@"mFormatFlags: %u", (unsigned int) audioStreamDescription.mFormatFlags);
        NSLog(@"mBytesPerPacket: %u", (unsigned int) audioStreamDescription.mBytesPerPacket);
        NSLog(@"mFramesPerPacket: %u", (unsigned int) audioStreamDescription.mFramesPerPacket);
        NSLog(@"mBytesPerFrame: %u", (unsigned int) audioStreamDescription.mBytesPerFrame);
        NSLog(@"mChannelsPerFrame: %u", (unsigned int) audioStreamDescription.mChannelsPerFrame);
        NSLog(@"mBitsPerChannel: %u", (unsigned int) audioStreamDescription.mBitsPerChannel);
        NSLog(@"mReserved: %u", (unsigned int) audioStreamDescription.mReserved);

        [self createConverter:&audioStreamDescription];
    }
}


void KKAudioFileStreamPacketsCallback(void *inClientData,
        UInt32 inNumberBytes,
        UInt32 inNumberPackets,
        const void *inInputData,
        AudioStreamPacketDescription *inPacketDescriptions) {
    MyAudioParser *self = (__bridge MyAudioParser *) inClientData;
    NSMutableArray *packets = [[NSMutableArray alloc] init];
    for (int i = 0; i < inNumberPackets; ++i) {
        SInt64 packetStart = inPacketDescriptions[i].mStartOffset;
        UInt32 packetSize = inPacketDescriptions[i].mDataByteSize;
        assert(packetSize > 0);
        NSData *packet = [NSData dataWithBytes:inInputData + packetStart length:packetSize];
        [packets addObject:packet];
    }
    [self parseDataComplete:packets];
}
