//
//  A440AppDelegate.h
//  A440
//
//  Created by Dave Dribin on 4/21/10.
//  Copyright 2010 Bit Maki, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class A440AudioQueue;

@interface A440AppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow * _window;
    NSButton * _startStopButton;
    A440AudioQueue * _a440AudioQueue;
}

@property (assign) IBOutlet NSWindow * window;
@property (assign) IBOutlet NSButton * startStopButton;

- (IBAction)startStop:(id)sender;

@end
