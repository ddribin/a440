//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioQueue.h>
#import "A440Player.h"


@interface A440AudioQueue : NSObject <A440Player>
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
