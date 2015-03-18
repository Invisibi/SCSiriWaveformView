//
//  SCViewController.m
//  SCSiriWaveformView
//
//  Created by Stefan Ceriu on 13/04/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCViewController.h"

#import <AVFoundation/AVFoundation.h>

#import "SCSiriWaveformView.h"

@interface SCViewController ()

@property (nonatomic, strong) AVAudioRecorder *recorder;

@property (nonatomic, weak) IBOutlet SCSiriWaveformView *waveformView;

@end

@implementation SCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    
	NSDictionary *settings = @{AVSampleRateKey:          [NSNumber numberWithFloat: 44100.0],
                               AVFormatIDKey:            [NSNumber numberWithInt: kAudioFormatAppleLossless],
                               AVNumberOfChannelsKey:    [NSNumber numberWithInt: 2],
                               AVEncoderAudioQualityKey: [NSNumber numberWithInt: AVAudioQualityMin]};
    
	NSError *error;
	self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    
    if(error) {
        NSLog(@"Ups, could not create recorder %@", error);
        return;
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
    }
    
    [self.recorder prepareToRecord];
    [self.recorder setMeteringEnabled:YES];
    [self.recorder record];
    
    CADisplayLink *displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMeters)];
    [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    
    
    [self.waveformView setWaveColors:@[[UIColor colorWithRed:0.45 green:0.8 blue:0.87 alpha:1],
                                       [UIColor colorWithRed:0.25 green:0.73 blue:0.57 alpha:1],
                                       [UIColor colorWithRed:0.92 green:0.65 blue:0.21 alpha:1],
                                       [UIColor colorWithRed:0.88 green:0.12 blue:0.4 alpha:1]]];
    [self.waveformView setPrimaryWaveLineWidth:3.0f];
    [self.waveformView setSecondaryWaveLineWidth:1.0];
    [self.waveformView setPhaseShift:-0.1f];
    [self.waveformView setIdleAmplitude:.2f];
    [self.waveformView setDensity:10.f];
    self.waveformView.backgroundColor = [UIColor whiteColor];
}


- (void)updateMeters
{
	[self.recorder updateMeters];
    
    CGFloat normalizedValue = pow (10, [self.recorder averagePowerForChannel:0] / 20);
    
    [self.waveformView updateWithLevel:normalizedValue];
}

@end
