//
//  PlayMusicViewController.h
//  MihPracSwift
//
//  Created by William Wang on 2017/9/13.
//  Copyright © 2017年 William Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SimpleAudioGraphPlayer.h"

@interface PlayMusicViewController : UIViewController <SimpleAudioGraphPlayerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIButton *playIconButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;

- (IBAction)playMusic:(id)sender;
- (IBAction)stopMusic:(id)sender;

@end
