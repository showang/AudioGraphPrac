//
//  SimplePlayer.h
//  MihPracSwift
//
//  Created by William Wang on 2017/9/14.
//  Copyright © 2017年 William Wang. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface SimpleAudioQueuePlayer : NSObject

- (id)initWithURL:(NSURL *)inURL;
- (void)play;
- (void)pause;

@property (readonly, getter=isPlaying) BOOL playing;

@end
