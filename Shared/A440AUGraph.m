//

#import "A440AUGraph.h"

#define FAIL_ON_ERR(_X_) if ((status = (_X_)) != noErr) { goto failed; }

@interface A440AUGraph ()
- (void)setupDataFormat;
- (void)setupSineWave;
@end

static OSStatus MyRenderer(void *							inRefCon,
                           AudioUnitRenderActionFlags *     ioActionFlags,
                           const AudioTimeStamp *			inTimeStamp,
                           UInt32							inBusNumber,
                           UInt32							inNumberFrames,
                           AudioBufferList *				ioData);

@implementation A440AUGraph

- (BOOL)start:(NSError **)error;
{
    NSAssert(_graph == NULL, @"Graph is already started");

    OSStatus status;
    
    FAIL_ON_ERR(NewAUGraph(&_graph));
    
    AudioComponentDescription description = {0};
    description.componentType = kAudioUnitType_Output;
    description.componentSubType = kAudioUnitSubType_DefaultOutput;
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    FAIL_ON_ERR(AUGraphAddNode(_graph, &description, &_outputNode));
    
    description.componentType = kAudioUnitType_FormatConverter;
    description.componentSubType = kAudioUnitSubType_AUConverter;
    FAIL_ON_ERR(AUGraphAddNode(_graph, &description, &_converterNode));
    
    FAIL_ON_ERR(AUGraphConnectNodeInput(_graph, _converterNode, 0, _outputNode, 0));
    
    FAIL_ON_ERR(AUGraphOpen(_graph));

    [self setupDataFormat];
    AudioUnit converterAudioUnit;
    FAIL_ON_ERR(AUGraphNodeInfo(_graph, _converterNode, NULL, &converterAudioUnit));

    FAIL_ON_ERR(AudioUnitSetProperty(converterAudioUnit,
                                     kAudioUnitProperty_StreamFormat,
                                     kAudioUnitScope_Input,
                                     0,
                                     &_dataFormat,
                                     sizeof(_dataFormat)));
    
    AURenderCallbackStruct callback = {
        .inputProc = MyRenderer,
        .inputProcRefCon = self,
    };
    FAIL_ON_ERR(AUGraphSetNodeInputCallback(_graph, _converterNode, 0, &callback));
    
    FAIL_ON_ERR(AUGraphInitialize(_graph));
    [self setupSineWave];
    FAIL_ON_ERR(AUGraphStart(_graph));
    
    return YES;
    
failed:
    if (_graph != NULL) {
        DisposeAUGraph(_graph);
    }
    
    if (error != NULL) {
        *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    }
    return NO;
}

- (void)setupDataFormat;
{
    // 16-bit native endian signed integer, stereo
    UInt32 formatFlags = (0
                          | kAudioFormatFlagIsPacked 
                          | kAudioFormatFlagIsSignedInteger 
                          | kAudioFormatFlagsNativeEndian
                          );
    
    memset(&_dataFormat, 0, sizeof(_dataFormat));
    _dataFormat.mFormatID = kAudioFormatLinearPCM;
    _dataFormat.mSampleRate = 44100.0;
    _dataFormat.mChannelsPerFrame = 2;
    _dataFormat.mFormatFlags = formatFlags;
    _dataFormat.mBitsPerChannel = 16;
    _dataFormat.mFramesPerPacket = 1;
    _dataFormat.mBytesPerFrame = _dataFormat.mBitsPerChannel * _dataFormat.mChannelsPerFrame / 8;
    _dataFormat.mBytesPerPacket = _dataFormat.mBytesPerFrame * _dataFormat.mFramesPerPacket;
}

- (void)setupSineWave;
{
    _currentPhase = 0.0;
    double frequency = 440.0;
    _phaseIncrement = (frequency * 2*M_PI)/_dataFormat.mSampleRate;
}

static OSStatus MyRenderer(void *							inRefCon,
                           AudioUnitRenderActionFlags *     ioActionFlags,
                           const AudioTimeStamp *			inTimeStamp,
                           UInt32							inBusNumber,
                           UInt32							inNumberFrames,
                           AudioBufferList *				ioData)
{
    A440AUGraph * self = inRefCon;
    
    int16_t * sample = ioData->mBuffers[0].mData;
    UInt32 channelsPerFrame = self->_dataFormat.mChannelsPerFrame;
    for (UInt32 i = 0; i < inNumberFrames; i++) {
        int16_t sineValue = 16384.0 * sin(self->_currentPhase);
        for (int channel = 0; channel < channelsPerFrame; channel++) {
            sample[channel] = sineValue;
        }
        self->_currentPhase += self->_phaseIncrement;
        sample += 2;
    }
    
    ioData->mBuffers[0].mDataByteSize = inNumberFrames*self->_dataFormat.mBytesPerFrame;
    
    // Keep the phase between 0 and 2*M_PI
    while (self->_currentPhase > 2*M_PI) {
        self->_currentPhase -= 2*M_PI;
    }

    return noErr;
}

- (BOOL)stop:(NSError **)error;
{
    NSAssert(_graph != NULL, @"Queue is not started");

    OSStatus status;
    
    FAIL_ON_ERR(AUGraphStop(_graph));
    FAIL_ON_ERR(AUGraphUninitialize(_graph));
    FAIL_ON_ERR(AUGraphClose(_graph));
    FAIL_ON_ERR(DisposeAUGraph(_graph));
    _graph = NULL;
    
    return YES;
    
failed:
    if (error != NULL) {
        *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    }
    return NO;
}

@end
