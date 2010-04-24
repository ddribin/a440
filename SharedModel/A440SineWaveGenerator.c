//

#include "A440SineWaveGenerator.h"
#include <math.h>

const Float64 SAMPLE_RATE = 44100.0;

void A440SineWaveGeneratorInitWithFrequency(A440SineWaveGenerator * self, double frequency)
{
    self->currentPhase = 0;
    
    // Given:
    //   frequency in cycles per second
    //   0x4000 angle units per sine wave cycle
    //   sample rate in samples per second
    //
    // Then:
    //   cycles     units     seconds     units
    //   ------  *  -----  *  -------  =  -----
    //   second     cycle     sample      sample
    self->phaseIncrement = round(frequency * 0x4000 / SAMPLE_RATE);
}

int16_t A440SineWaveGeneratorNextSample(A440SineWaveGenerator * self)
{
    // There are 2*M_PI radians per sine wave cycle
    double phaseInRadians = ((double)self->currentPhase) * 2*M_PI / 0x4000;
    int16_t sample = INT16_MAX * sin(phaseInRadians);
    
    self->currentPhase += self->phaseIncrement;
    // Keep the value between 0 and 0x3FFF.
    self->currentPhase &= 0x3FFF;
    
    return sample;
}
