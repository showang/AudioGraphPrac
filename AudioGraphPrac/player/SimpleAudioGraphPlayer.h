//
//  SimpleAudioGraphPlayer.h
//  MihPracSwift
//
//  Created by William Wang on 2017/9/14.
//  Copyright © 2017年 William Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class SimpleAudioGraphPlayer;

typedef enum : NSInteger {
    STOP, BUFFERING, PREPARED, PLAYING, PAUSE
} PlayerState;

@protocol SimpleAudioGraphPlayerDelegate

- (void)SimpleAudioGraphPlayer:(SimpleAudioGraphPlayer *)player updateWith:(PlayerState)state;

@end

@interface SimpleAudioGraphPlayer : NSObject

- (instancetype)initWithDelegate:(id <SimpleAudioGraphPlayerDelegate>)delegate;

- (void)play;

- (void)pause;

-(void) stop;

- (void)startWithUrl:(NSString *)url;

@property(readonly, nonatomic) CFArrayRef iPodEQPresetsArray;
@property(nonatomic, readonly) PlayerState state;
@property (readwrite, nonatomic) id<SimpleAudioGraphPlayerDelegate> delegate;

- (void)selectEQPreset:(NSInteger)value;
@end


