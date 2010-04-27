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

#import "A440AppDelegate.h"
#import "A440AudioQueue.h"
#import "A440AUGraph.h"

@interface A440AppDelegate ()
@property (nonatomic, readonly, getter=isPlaying) BOOL playing;

- (void)play;
- (id<A440Player>)newPlayerOfSelectedType;
- (BOOL)playPlayer;
- (void)updateUiToPlayingState;

- (void)stop;
- (BOOL)stopPlayer;
- (void)releasePlayer;
- (void)updateUiToStoppedState;

- (BOOL)presentError:(NSError *)error;
@end

Class sRowToClass[2];

@implementation A440AppDelegate

@synthesize window = _window;
@synthesize startStopButton = _startStopButton;
@synthesize playerTypeMatrix = _playerTypeMatrix;

+ (void)initialize
{
    if (self != [A440AppDelegate class]) {
        return;
    }
    
    sRowToClass[0] = [A440AudioQueue class];
    sRowToClass[1] = [A440AUGraph class];
}

- (void)dealloc
{
    [_player release];
    [super dealloc];
}

- (IBAction)playStop:(id)sender;
{
    if (!self.isPlaying) {
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
    _player = [self newPlayerOfSelectedType];
    if (![self playPlayer]) {
        return;
    }
    [self updateUiToPlayingState];
}

- (id<A440Player>)newPlayerOfSelectedType;
{
    NSUInteger row = [_playerTypeMatrix selectedRow];
    Class playerClass = sRowToClass[row];
    id<A440Player> player = [[playerClass alloc] init];
    NSLog(@"Player: %@", player);
    return player;
}

- (BOOL)playPlayer;
{
    NSError * error = nil;
    if (![_player play:&error]) {
        [self presentError:error];
        [_player release];
        _player = nil;
        return NO;
    }
    return YES;
}

- (void)updateUiToPlayingState;
{
    [_startStopButton setTitle:@"Stop"];
    [_playerTypeMatrix setEnabled:NO];
}

#pragma mark -

- (void)stop;
{
    if (![self stopPlayer]) {
        return;
    }
    [self releasePlayer];
    [self updateUiToStoppedState];
}

- (BOOL)stopPlayer;
{
    NSError * error = nil;
    if (![_player stop:&error]) {
        [self presentError:error];
        return NO;
    }
    return YES;
}

- (void)releasePlayer;
{
    [_player release];
    _player = nil;
}

- (void)updateUiToStoppedState;
{
    [_startStopButton setTitle:@"Play"];
    [_playerTypeMatrix setEnabled:YES];
}

#pragma mark -

- (BOOL)presentError:(NSError *)error;
{
    NSLog(@"error: %@ %@", error, [error userInfo]);
    [NSApp presentError:error];
    return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application
{
    return YES;
}

@end
