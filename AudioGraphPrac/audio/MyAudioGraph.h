//
// Created by William Wang on 2017/9/19.
// Copyright (c) 2017 William Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MyAudioNode;


@interface MyAudioGraph : NSObject

- (AUGraph)auGraph;

- (void)addNode:(MyAudioNode *)node;

- (void)initialize;

- (void)finish;

- (void) showStatus;

@end

@protocol GraphControlInterface

- (AUGraph)auGraph;

@end