/*
 * Copyright (c) 2010 Dave Dribin
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "MainViewController.h"
#import "A440Player.h"
#import "A440AudioQueue.h"
#import "A440AUGraph.h"

@interface MainViewController ()
@property (nonatomic, readonly, getter=isPlaying) BOOL playing;
- (void)setupAudioSession;
- (void)setupAudioSessionCategory;
- (void)activateAudioSession;

- (void)play;
- (id<A440Player>)newPlayerOfSelectedType;
- (void)playPlayer;
- (void)disablePlayerTypeSegementedControl;

- (void)stop;
- (void)stopPlayer;
- (void)releasePlayer;
- (void)enablePlayerTypeSegmentedControl;
@end

static Class sRowToClass[2];

@implementation MainViewController

@synthesize playerTypeSegmentedControl = _playerTypeSegmentedControl;

+ (void)initialize
{
    if (self != [MainViewController class]) {
        return;
    }
    
    sRowToClass[0] = [A440AudioQueue class];
    sRowToClass[1] = [A440AUGraph class];
}

- (void)dealloc
{
    [_player release];
    [_playerTypeSegmentedControl release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupAudioSession];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.playerTypeSegmentedControl = nil;
}

#pragma mark -
#pragma mark Audio session handling

- (void)setupAudioSession;
{
    [self activateAudioSession];
    [[AVAudioSession sharedInstance] setDelegate:self];
    [self setupAudioSessionCategory];
}

- (void)setupAudioSessionCategory;
{
    NSError * error;
    AVAudioSession * session = [AVAudioSession sharedInstance];
    if (![session setCategory:AVAudioSessionCategoryPlayback error:&error]) {
        NSLog(@"Could not set audio session category: %@ %@", error, [error userInfo]);
    }
}

- (void)beginInterruption;
{
    _playOnEndInterruption = self.isPlaying;
    [self stop];
}

- (void)endInterruption;
{
    [self activateAudioSession];

    if (_playOnEndInterruption) {
        [self play];
    }
}

- (void)activateAudioSession;
{
    NSError * error = nil;
    AVAudioSession * session = [AVAudioSession sharedInstance];
    if (![session setActive:YES error:&error]) {
        NSLog(@"Could not activate audio session: %@ %@", error, [error userInfo]);
        return;
    }
}

#pragma mark -
#pragma mark Player control

- (IBAction)playStop:(id)sender;
{
    UISwitch * playerSwitch = sender;
    if (playerSwitch.on) {
        [self play];
    } else {
        [self stop];
    }
}

- (BOOL)isPlaying;
{
    BOOL isPlaying = (_player != nil);
    return isPlaying;
}

- (void)play;
{
    if (self.isPlaying) {
        return;
    }
    
    _player = [self newPlayerOfSelectedType];
    [self playPlayer];
    [self disablePlayerTypeSegementedControl];
}   

- (id<A440Player>)newPlayerOfSelectedType;
{
    NSInteger selectedIndex = _playerTypeSegmentedControl.selectedSegmentIndex;
    Class playerClass = sRowToClass[selectedIndex];
    id<A440Player> player = [[playerClass alloc] init];
    NSLog(@"Player: %@", player);
    return player;
}

- (void)playPlayer;
{
    NSError * error = nil;
    if (![_player play:&error]) {
        NSLog(@"Could not play player: %@ %@", error, [error userInfo]);
    }
}

- (void)disablePlayerTypeSegementedControl;
{
    // Not quite sure why, but you have to set the selected segment after disabling
    NSInteger selectedIndex = _playerTypeSegmentedControl.selectedSegmentIndex;
    [_playerTypeSegmentedControl setEnabled:NO forSegmentAtIndex:0];
    [_playerTypeSegmentedControl setEnabled:NO forSegmentAtIndex:1];
    [_playerTypeSegmentedControl setSelectedSegmentIndex:selectedIndex];
}

#pragma mark -

- (void)stop;
{
    if (!self.isPlaying) {
        return;
    }
    
    [self stopPlayer];
    [self releasePlayer];
    [self enablePlayerTypeSegmentedControl];
}

- (void)stopPlayer;
{
    NSError * error = nil;
    if (![_player stop:&error]) {
        NSLog(@"Could not stop player: %@ %@", error, [error userInfo]);
    }
}

- (void)releasePlayer;
{
    [_player release];
    _player = nil;
}

- (void)enablePlayerTypeSegmentedControl;
{
    [_playerTypeSegmentedControl setEnabled:YES forSegmentAtIndex:0];
    [_playerTypeSegmentedControl setEnabled:YES forSegmentAtIndex:1];
}

@end
