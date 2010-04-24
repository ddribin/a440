//

#include <stdint.h>
#import <AudioToolbox/AudioToolbox.h>

typedef struct
{
    // Internally, store the phase as an integer from 0 - 0x3FFF (instead of 0 - 2*M_PI)
    uint16_t currentPhase;
    uint16_t phaseIncrement;
} A440SineWaveGenerator;

extern const Float64 SAMPLE_RATE;

/**
 * For a list of frequencies:
 * http://en.wikipedia.org/wiki/Piano_key_frequencies
 */
void A440SineWaveGeneratorInitWithFrequency(A440SineWaveGenerator * generator, double frequency);
int16_t A440SineWaveGeneratorNextSample(A440SineWaveGenerator * generator);
