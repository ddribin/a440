//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import "A440Player.h"
#import "A440SineWaveGenerator.h"


@interface A440AUGraph : NSObject <A440Player>
{
    AUGraph _graph;
    AUNode _outputNode;
    AUNode _converterNode;
    AudioStreamBasicDescription _dataFormat;
    
    A440SineWaveGenerator _sineWaveGenerator;
}

- (BOOL)play:(NSError **)error;
- (BOOL)stop:(NSError **)error;

@end
