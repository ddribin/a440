//
//  A440AudioQueue.h
//  A440
//
//  Created by Dave Dribin on 4/21/10.
//  Copyright 2010 Bit Maki, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioQueue.h>


@interface A440AudioQueue : NSObject
{
    AudioQueueRef _queue;
    AudioStreamBasicDescription _dataFormat;
    AudioQueueBufferRef _buffers[3];
    
    double _currentPhase;
    double _phaseIncrement;
    BOOL _shouldBufferDataInCallback;
}

- (BOOL)start:(NSError **)error;
- (BOOL)stop:(NSError **)error;

@end
