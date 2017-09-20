//
//  PlayMusicViewController.m
//  MihPracSwift
//
//  Created by William Wang on 2017/9/13.
//  Copyright © 2017年 William Wang. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "PlayMusicViewController.h"
#import "SimpleAudioGraphPlayer.h"

@interface PlayMusicViewController () {
//    SimpleAudioQueuePlayer *player;
    SimpleAudioGraphPlayer *player;
}
@end

@implementation PlayMusicViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        player = [[SimpleAudioGraphPlayer alloc] initWithDelegate:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.urlTextField.text = @"https://dl-web.dropbox.com/s/dhq5c72a4cqout2/Epic%20Sax%20Guy%20%5BOriginal%5D%20%5BHD%5D.mp3?dl=0";
    [self.playIconButton setImage:[UIImage imageNamed:@"player-play"] forState:UIControlStateNormal];
    [self.stopButton setImage:[UIImage imageNamed:@"player-stop"] forState:UIControlStateNormal];
    [self.loadingIndicator setHidden:YES];
}

- (IBAction)playMusic:(id)sender {
    switch (player.state) {
        case STOP:
            [player startWithUrl:[self.urlTextField text]];
        case PAUSE:
            [player play];
            break;
        case PLAYING:
            [player pause];
            break;
        default:
            break;
    }
}

- (IBAction)stopMusic:(id)sender {
    [player stop];
}

- (void)SimpleAudioGraphPlayer:(SimpleAudioGraphPlayer *)player1 updateWith:(PlayerState)state {
    [self.loadingIndicator setHidden:YES];
    switch (state) {
        case PLAYING:
            [self.playButton setTitle:@"Pause" forState:UIControlStateNormal];
            [self updatePlayerIcon:@"player-pause"];
            break;
        case PAUSE:
            [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
            [self updatePlayerIcon:@"player-play"];
            break;
        case STOP:
            [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
            [self updatePlayerIcon:@"player-play"];
            break;
        case BUFFERING:
            [self.playButton setTitle:@"Buffering" forState:UIControlStateNormal];
            [self.loadingIndicator setHidden:NO];
            [self.loadingIndicator startAnimating];
            break;
        default:
            [self.playButton setTitle:@"Unknown" forState:UIControlStateNormal];
            break;
    }
}

- (void)updatePlayerIcon:(NSString *)imageName {
    [self.playIconButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}


@end
