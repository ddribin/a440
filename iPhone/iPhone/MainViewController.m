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
- (void)play;
- (void)stop;
@end

static Class sRowToClass[2];

@implementation MainViewController

@synthesize playerTypePicker = _playerTypePicker;

+ (void)initialize
{
    if (self != [MainViewController class]) {
        return;
    }
    
    sRowToClass[0] = [A440AudioQueue class];
    sRowToClass[1] = [A440AUGraph class];
}

#if 0
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self == nil) {
        return nil;
    }
    
    return self;
}
#endif

- (void)dealloc
{
    [_player release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupAudioSession];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
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
}

#pragma mark -
#pragma mark Audio session handling

- (void)setupAudioSession;
{
    AVAudioSession * session = [AVAudioSession sharedInstance];
    NSError * error = nil;
    if (![session setActive:YES error:&error]) {
        NSLog(@"Could not activate audio session: %@ %@", error, [error userInfo]);
        return;
    }
    
    [session setDelegate:self];
    if (![session setCategory:AVAudioSessionCategoryPlayback error:&error]) {
        NSLog(@"Could not seet audio session category: %@ %@", error, [error userInfo]);
    }
}

- (void)beginInterruption;
{
    _playOnEndInterruption = self.isPlaying;
    [self stop];
}

- (void)endInterruption;
{
    NSError * error = nil;
    if (![[AVAudioSession sharedInstance] setActive:YES error:&error]) {
        NSLog(@"Could not activate audio session: %@ %@", error, [error userInfo]);
        return;
    }

    if (_playOnEndInterruption) {
        [self play];
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
    
    NSInteger row = [_playerTypePicker selectedRowInComponent:0];
    Class playerClass = sRowToClass[row];
    _player = [[playerClass alloc] init];
    NSLog(@"Player: %@", _player);
    
    NSError * error = nil;
    if (![_player play:&error]) {
        NSLog(@"Could not start: %@ %@", error, [error userInfo]);
    }
}   

- (void)stop;
{
    if (!self.isPlaying) {
        return;
    }
    
    NSError * error = nil;
    if (![_player stop:&error]) {
        NSLog(@"Could not stop: %@ %@", error, [error userInfo]);
    }
    
    [_player release];
    _player = nil;
}

#pragma mark - UIPickerView

static NSString * sRowToLabel[] = {
    @"Audio Queue",
    @"AUGraph",
};

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView
{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component
{
	return (sizeof(sRowToLabel)/sizeof(*sRowToLabel));
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return sRowToLabel[row];
}

@end
