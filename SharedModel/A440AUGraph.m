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

#import "A440AUGraph.h"

#define FAIL_ON_ERR(_X_) if ((status = (_X_)) != noErr) { goto failed; }

@interface A440AUGraph ()
- (OSStatus)addOutputNode;
- (OSStatus)addConverterNode;
- (OSStatus)setDataFormatOfConverterAudioUnit;
- (OSStatus)setMaximumFramesPerSlice;
- (OSStatus)setRenderCallbackOfConverterNode;
- (void)setupDataFormat;
@end

static OSStatus MyRenderer(void *                           inRefCon,
                           AudioUnitRenderActionFlags *     ioActionFlags,
                           const AudioTimeStamp *           inTimeStamp,
                           UInt32                           inBusNumber,
                           UInt32                           inNumberFrames,
                           AudioBufferList *                ioData);

static void FillFrame(A440AUGraph * self, int16_t * sample);

@implementation A440AUGraph

- (BOOL)play:(NSError **)error;
{
    NSAssert(_graph == NULL, @"Graph is already started");

    OSStatus status;
    
    FAIL_ON_ERR(NewAUGraph(&_graph));
    FAIL_ON_ERR([self addOutputNode]);
    FAIL_ON_ERR([self addConverterNode]);
    FAIL_ON_ERR(AUGraphConnectNodeInput(_graph, _converterNode, 0,
                                        _outputNode, 0));
    FAIL_ON_ERR(AUGraphOpen(_graph));
    [self setupDataFormat];
    FAIL_ON_ERR([self setDataFormatOfConverterAudioUnit]);
    FAIL_ON_ERR([self setMaximumFramesPerSlice]);
    FAIL_ON_ERR([self setRenderCallbackOfConverterNode]);
    FAIL_ON_ERR(AUGraphInitialize(_graph));
    A440SineWaveGeneratorInitWithFrequency(&_sineWaveGenerator, 440.0);
    FAIL_ON_ERR(AUGraphStart(_graph));
    
    return YES;
    
failed:
    // Error handling...
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
    AudioComponentDescription description = {
        .componentType = kAudioUnitType_Output,
#if TARGET_OS_IPHONE
        .componentSubType = kAudioUnitSubType_RemoteIO,
#else
        .componentSubType = kAudioUnitSubType_DefaultOutput,
#endif
        .componentManufacturer = kAudioUnitManufacturer_Apple,
    };
    return AUGraphAddNode(_graph, &description, &_outputNode);
}

- (OSStatus)addConverterNode;
{
    AudioComponentDescription description = {
        .componentType = kAudioUnitType_FormatConverter,
        .componentSubType = kAudioUnitSubType_AUConverter,
        .componentManufacturer = kAudioUnitManufacturer_Apple,
    };
    return AUGraphAddNode(_graph, &description, &_converterNode);
}

- (void)setupDataFormat;
{
    // 16-bit native endian signed integer, stereo LPCM
    UInt32 formatFlags = (0
                          | kAudioFormatFlagIsPacked 
                          | kAudioFormatFlagIsSignedInteger 
                          | kAudioFormatFlagsNativeEndian
                          );
    
    _dataFormat = (AudioStreamBasicDescription) {
        .mFormatID = kAudioFormatLinearPCM,
        .mFormatFlags = formatFlags,
        .mSampleRate = SAMPLE_RATE,
        .mBitsPerChannel = 16,
        .mChannelsPerFrame = 2,
        .mBytesPerFrame = 4,
        .mFramesPerPacket = 1,
        .mBytesPerPacket = 4,
    };
}

- (OSStatus)setDataFormatOfConverterAudioUnit;
{
    AudioUnit converterAudioUnit;
    OSStatus status;
    status = AUGraphNodeInfo(_graph, _converterNode,
                             NULL, &converterAudioUnit);
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

- (OSStatus)setMaximumFramesPerSlice;
{
#if TARGET_OS_IPHONE
    /*
     * See Technical Q&A QA1606 Audio Unit Processing Graph -
     *   Ensuring audio playback continues when screen is locked
     *
     * http://developer.apple.com/iphone/library/qa/qa2009/qa1606.html
     *
     * Need to set kAudioUnitProperty_MaximumFramesPerSlice to 4096 on all
     * non-output audio units.  In this case, that's only the converter unit.
     */
    
    AudioUnit converterAudioUnit;
    OSStatus status;
    status = AUGraphNodeInfo(_graph, _converterNode,
                             NULL, &converterAudioUnit);
    if (status != noErr) {
        return status;
    }

    AudioUnitSetProperty(converterAudioUnit,
                         kAudioUnitProperty_MaximumFramesPerSlice,
                         kAudioUnitScope_Global,
                         0,
                         &(UInt32) {4096},
                         sizeof(UInt32));

    return status;
    
#else
    // Don't bother on the desktop.
    return noErr;
#endif
}

- (OSStatus)setRenderCallbackOfConverterNode;
{
    AURenderCallbackStruct callback = {
        .inputProc = MyRenderer,
        .inputProcRefCon = self,
    };
    return AUGraphSetNodeInputCallback(_graph, _converterNode,
                                       0, &callback);
}

static OSStatus MyRenderer(
    void *                       inRefCon,
    AudioUnitRenderActionFlags * ioActionFlags,
    const AudioTimeStamp *       inTimeStamp,
    UInt32                       inBusNumber,
    UInt32                       inNumberFrames,
    AudioBufferList *            ioData)
{
    A440AUGraph * self = inRefCon;
    
    int16_t * sample = ioData->mBuffers[0].mData;
    UInt32 channelsPerFrame = self->_dataFormat.mChannelsPerFrame;
    
    for (UInt32 i = 0; i < inNumberFrames; i++) {
        FillFrame(self, sample);
        sample += channelsPerFrame;
    }
    
    ioData->mBuffers[0].mDataByteSize =
        inNumberFrames*self->_dataFormat.mBytesPerFrame;
    
    return noErr;
}

static void FillFrame(A440AUGraph * self, int16_t * sample)
{
    A440SineWaveGenerator * generator = &self->_sineWaveGenerator;
    int16_t sampleValue =
        A440SineWaveGeneratorNextSample(generator);
    // Divide by four to keep the volume away from the max
    sampleValue /= 4;
    
    // Fill two channels
    sample[0] = sampleValue;
    sample[1] = sampleValue;
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
