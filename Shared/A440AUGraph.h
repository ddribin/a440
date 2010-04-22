//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import "A440Player.h"


@interface A440AUGraph : NSObject <A440Player>
{
    AUGraph _graph;
    AUNode _outputNode;
    AUNode _converterNode;
    AudioStreamBasicDescription _dataFormat;
    
    double _currentPhase;
    double _phaseIncrement;
}

- (BOOL)start:(NSError **)error;
- (BOOL)stop:(NSError **)error;

@end
