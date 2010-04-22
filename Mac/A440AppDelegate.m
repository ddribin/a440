//
//  A440AppDelegate.m
//  A440
//
//  Created by Dave Dribin on 4/21/10.
//  Copyright 2010 Bit Maki, Inc. All rights reserved.
//

#import "A440AppDelegate.h"
#import "A440AudioQueue.h"

@interface A440AppDelegate ()
- (void)start;
- (void)stop;
@end

@implementation A440AppDelegate

@synthesize window = _window;
@synthesize startStopButton = _startStopButton;

- (void)dealloc
{
    [_a440AudioQueue release];
    [super dealloc];
}

- (IBAction)startStop:(id)sender;
{
    if (_a440AudioQueue == nil) {
        [self start];
    } else {
        [self stop];
    }
}

- (void)start;
{
    _a440AudioQueue = [[A440AudioQueue alloc] init];
    NSError * error = nil;
    if (![_a440AudioQueue start:&error]) {
        [NSApp presentError:error];
        [_a440AudioQueue release];
        _a440AudioQueue = nil;
        return;
    }
    [_startStopButton setTitle:@"Stop"];
}

- (void)stop;
{
    NSError * error = nil;
    if (![_a440AudioQueue stop:&error]) {
        [NSApp presentError:error];
        return;
    }
    
    [_a440AudioQueue release];
    _a440AudioQueue = nil;
    [_startStopButton setTitle:@"Start"];
}

@end
