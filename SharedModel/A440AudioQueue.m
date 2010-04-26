//

#import "A440AudioQueue.h"


#define kNumberBuffers (sizeof(_buffers)/sizeof(*_buffers))

#define FAIL_ON_ERR(_X_) if ((status = (_X_)) != noErr) { goto failed; }

@interface A440AudioQueue ()
- (void)setupDataFormat;
- (OSStatus)allocateBuffers;
- (UInt32)calculateBufferSizeForSeconds:(Float64)seconds;
- (void)primeBuffers;
@end

static void HandleOutputBuffer(void * inUserData,
                               AudioQueueRef inAQ,
                               AudioQueueBufferRef inBuffer);

@implementation A440AudioQueue

- (void)dealloc
{
    if (_queue != NULL) {
        [self stop:NULL];
    }
    [super dealloc];
}

- (BOOL)play:(NSError **)error;
{
    NSAssert(_queue == NULL, @"Queue is already setup");

    OSStatus status;
    
    [self setupDataFormat];
    FAIL_ON_ERR(AudioQueueNewOutput(&_dataFormat, HandleOutputBuffer, self, CFRunLoopGetCurrent(),
                                    kCFRunLoopCommonModes, 0, &_queue));
    FAIL_ON_ERR([self allocateBuffers]);
    A440SineWaveGeneratorInitWithFrequency(&_sineWaveGenerator, 440.0);
    [self primeBuffers];
    FAIL_ON_ERR(AudioQueueStart(_queue, NULL));
    return YES;
    
failed:
    if (_queue != NULL) {
        AudioQueueDispose(_queue, YES);
        _queue = NULL;
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
    _dataFormat.mSampleRate = SAMPLE_RATE;
    _dataFormat.mChannelsPerFrame = 2;
    _dataFormat.mFormatFlags = formatFlags;
    _dataFormat.mBitsPerChannel = 16;
    _dataFormat.mFramesPerPacket = 1;
    _dataFormat.mBytesPerFrame = _dataFormat.mBitsPerChannel * _dataFormat.mChannelsPerFrame / 8;
    _dataFormat.mBytesPerPacket = _dataFormat.mBytesPerFrame * _dataFormat.mFramesPerPacket;
}

- (OSStatus)allocateBuffers;
{
    UInt32 bufferSize = [self calculateBufferSizeForSeconds:0.5];
    
    OSStatus status;
    for (int i = 0; i < kNumberBuffers; ++i) {
        status = AudioQueueAllocateBuffer(_queue, bufferSize, &_buffers[i]);
        if (status != noErr) {
            goto failed;
        }
    }
    return noErr;
    
failed:
    return status;
}

- (UInt32)calculateBufferSizeForSeconds:(Float64)seconds;
{
    UInt32 bufferSize = _dataFormat.mSampleRate * _dataFormat.mBytesPerPacket * seconds;
    return bufferSize;
}

- (void)primeBuffers;
{
    _shouldBufferDataInCallback = YES;
    for (int i = 0; i < kNumberBuffers; ++i) {
        HandleOutputBuffer(self, _queue, _buffers[i]);
    }
}

#pragma mark -

static void HandleOutputBuffer(void * inUserData,
                               AudioQueueRef inAQ,
                               AudioQueueBufferRef inBuffer)
{
    A440AudioQueue * self = inUserData;
    
    if (!self->_shouldBufferDataInCallback) {
        return;
    }
    
    UInt32 numberOfFrames = inBuffer->mAudioDataBytesCapacity / self->_dataFormat.mBytesPerFrame;
    int16_t * sample = inBuffer->mAudioData;
    UInt32 channelsPerFrame = self->_dataFormat.mChannelsPerFrame;
    for (UInt32 i = 0; i < numberOfFrames; i++) {
        // Divide by four to keep the volume away from the max
        int16_t sampleValue = A440SineWaveGeneratorNextSample(&self->_sineWaveGenerator) / 4;
        for (int channel = 0; channel < channelsPerFrame; channel++) {
            sample[channel] = sampleValue;
        }
        sample += channelsPerFrame;
    }
    
    inBuffer->mAudioDataByteSize = numberOfFrames * self->_dataFormat.mBytesPerFrame;
    OSStatus result = AudioQueueEnqueueBuffer(self->_queue, inBuffer, 0, NULL);
    if (result != noErr) {
        NSLog(@"AudioQueueEnqueueBuffer error: %d", result);
    }
}

#pragma mark -

- (BOOL)stop:(NSError **)error;
{
    NSAssert(_queue != NULL, @"Queue is not setup");
    
    OSStatus status;
    _shouldBufferDataInCallback = NO;
    FAIL_ON_ERR(AudioQueueStop(_queue, YES));
    FAIL_ON_ERR(AudioQueueDispose(_queue, YES));
    _queue = NULL;
    return YES;
    
failed:
    if (error != NULL) {
        *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    }
    return NO;
}

@end
