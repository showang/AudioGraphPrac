//
// Created by William Wang on 2017/9/19.
// Copyright (c) 2017 William Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyAudioNode.h"


@interface MyAudioNodeMixer : MyAudioNode

- (instancetype) initWithGraph:(MyAudioGraph *) graph;

@end