//

#import "A440AUGraph.h"

#define FAIL_ON_ERR(_X_) if ((status = (_X_)) != noErr) { goto failed; }

@interface A440AUGraph ()
- (OSStatus)addOutputNode;
- (OSStatus)addConverterNode;
- (OSStatus)setDataFormatOfConverterAudioUnit;
- (OSStatus)setRenderCallbackOfConverterNode;
- (void)setupDataFormat;
@end

static OSStatus MyRenderer(void *                           inRefCon,
                           AudioUnitRenderActionFlags *     ioActionFlags,
                           const AudioTimeStamp *           inTimeStamp,
                           UInt32                           inBusNumber,
                           UInt32                           inNumberFrames,
                           AudioBufferList *                ioData);

@implementation A440AUGraph

- (BOOL)start:(NSError **)error;
{
    NSAssert(_graph == NULL, @"Graph is already started");

    OSStatus status;
    
    FAIL_ON_ERR(NewAUGraph(&_graph));
    FAIL_ON_ERR([self addOutputNode]);
    FAIL_ON_ERR([self addConverterNode]);
    FAIL_ON_ERR(AUGraphConnectNodeInput(_graph, _converterNode, 0, _outputNode, 0));
    FAIL_ON_ERR(AUGraphOpen(_graph));
    [self setupDataFormat];
    FAIL_ON_ERR([self setDataFormatOfConverterAudioUnit]);
    FAIL_ON_ERR([self setRenderCallbackOfConverterNode]);
    FAIL_ON_ERR(AUGraphInitialize(_graph));
    A440SineWaveGeneratorInitWithFrequency(&_sineWaveGenerator, 440.0);
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

- (OSStatus)addOutputNode;
{
    AudioComponentDescription description = {0};
    description.componentType = kAudioUnitType_Output;
#if TARGET_OS_IPHONE
    description.componentSubType = kAudioUnitSubType_RemoteIO;
#else
    description.componentSubType = kAudioUnitSubType_DefaultOutput;
#endif
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    return AUGraphAddNode(_graph, &description, &_outputNode);
}

- (OSStatus)addConverterNode;
{
    AudioComponentDescription description = {0};
    description.componentType = kAudioUnitType_FormatConverter;
    description.componentSubType = kAudioUnitSubType_AUConverter;
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    return AUGraphAddNode(_graph, &description, &_converterNode);
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
    _dataFormat.mSampleRate = SAMPLE_RATE;
    _dataFormat.mChannelsPerFrame = 2;
    _dataFormat.mFormatFlags = formatFlags;
    _dataFormat.mBitsPerChannel = 16;
    _dataFormat.mFramesPerPacket = 1;
    _dataFormat.mBytesPerFrame = _dataFormat.mBitsPerChannel * _dataFormat.mChannelsPerFrame / 8;
    _dataFormat.mBytesPerPacket = _dataFormat.mBytesPerFrame * _dataFormat.mFramesPerPacket;
}

- (OSStatus)setDataFormatOfConverterAudioUnit;
{
    AudioUnit converterAudioUnit;
    OSStatus status;
    status = AUGraphNodeInfo(_graph, _converterNode, NULL, &converterAudioUnit);
    if (status != noErr) {
        return status;
    }
    
    status = AudioUnitSetProperty(converterAudioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &_dataFormat,
                                  sizeof(_dataFormat));
    return status;
}

- (OSStatus)setRenderCallbackOfConverterNode;
{
    AURenderCallbackStruct callback = {
        .inputProc = MyRenderer,
        .inputProcRefCon = self,
    };
    return AUGraphSetNodeInputCallback(_graph, _converterNode, 0, &callback);
}

static OSStatus MyRenderer(void *                           inRefCon,
                           AudioUnitRenderActionFlags *     ioActionFlags,
                           const AudioTimeStamp *           inTimeStamp,
                           UInt32                           inBusNumber,
                           UInt32                           inNumberFrames,
                           AudioBufferList *                ioData)
{
    A440AUGraph * self = inRefCon;
    
    int16_t * sample = ioData->mBuffers[0].mData;
    UInt32 channelsPerFrame = self->_dataFormat.mChannelsPerFrame;
    for (UInt32 i = 0; i < inNumberFrames; i++) {
        // Divide by four to keep the volume away from the max
        int16_t sampleValue = A440SineWaveGeneratorNextSample(&self->_sineWaveGenerator) / 4;
        for (int channel = 0; channel < channelsPerFrame; channel++) {
            sample[channel] = sampleValue;
        }
        sample += channelsPerFrame;
    }
    
    ioData->mBuffers[0].mDataByteSize = inNumberFrames*self->_dataFormat.mBytesPerFrame;
    
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
