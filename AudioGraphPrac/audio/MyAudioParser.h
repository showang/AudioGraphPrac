//
// Created by William Wang on 2017/9/18.
// Copyright (c) 2017 William Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyAudioParser : NSObject

- (instancetype)initWithOutputStreamDescription:(AudioStreamBasicDescription)description
                                      audioType:(AudioFileTypeID)type;
- (void)open;
- (void)close;
- (void)parsePacketData:(NSData *)data complete:(void (^)(NSArray<NSData *> *))parsedPackets;
- (AudioConverterRef)converter;

@end

