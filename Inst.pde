/* FMInst - FM Instrument class by Al Biles
 from a Processing example by Damien Di Fede
 Intended to become a portable FM instrument for all ocassions
 but used here just to display how FM works
 */

class FMInst
{
  // Carrier Oscillator
  Oscil car;
  float carF;
  float carAmp;
  // Modulating Oscillator
  Oscil mod;
  float modF;
  float modAmp;
  float modOff;
  
  Oscil amp;
  float ampF;
  float ampAmp;

  float xOff = random(0.0, 2.0);
  float xIncrement = 0.005; 
  float yOff = random(0.0, 2.0);
  float yIncrement = 0.005; 
  float zOff = random(0.0, 2.0);
  float zIncrement = 0.005; 
  
  AudioOutput out;

  // Constructor takes modulating frequency, amplitude and offset (carrier f)
  FMInst(float mF, float mA, float mO, float pan, AudioOutput _out)
  {
    out = _out;
    carF = 300;      // Doesn't matter, replaced by modulator output
    carAmp = 0.6;    // Does matter but hardwired to give reasonable spectra
    modF = mF;
    modAmp = mA;
    modOff = mO;     // Really the carrier frequency
    ampF = 10;
    ampAmp = 1;

    // Make the Oscil we will hear (carrier).
    // Arguments are frequency, amplitude, and waveform
    car = new Oscil( carF, carAmp, Waves.SINE );

    // Make the Oscil we will use to modulate the frequency of carrier.
    // The frequency of this Oscil will determine how quickly the
    // frequency of wave changes and the amplitude determines how much.
    // Since we are using the output of FM directly to set the frequency 
    // of wave, you can think of the amplitude as being expressed in Hz.
    mod = new Oscil( modF, modAmp, Waves.SINE );

    // Set the offset of FM so that it generates values centered around modOff Hz
    // In other words, set the carrier frequency
    mod.offset.setLastValue( modOff );

    // Patch modulator output to frequency of the carrier to control carrier's freq
    mod.patch( car.frequency );
    
    amp = new Oscil(ampF, ampAmp, Waves.SINE);
    amp.patch(car.amplitude);

    // and patch carrier to the output to hear it (and draw the spectrum)
    car.patch( out );
    out.setPan(pan);
  }

  void move()
  {
    // Use perlin noise to wander carrier freq and modulator freq & amplitude
    modF = modF + (noise(xOff) - 0.5);
    mod.frequency.setLastValue( modF );
    xOff += xIncrement;
    
    modAmp = modAmp + (noise(yOff) - 0.5);
    mod.amplitude.setLastValue( modAmp );
    yOff += yIncrement;

    modOff = modOff + (noise(zOff) - 0.5);
    mod.offset.setLastValue( modOff );
    zOff += zIncrement;
  }

  // A bunch of setters for the FM parameters
  void setModF(float f)
  {
    modF = f;
    mod.frequency.setLastValue( modF );
  }
  
  void setAmpF(float f){
    ampF = f;
    amp.frequency.setLastValue(ampF);
  }

  void setModAmp(float a)
  {
    modAmp = a;
    mod.amplitude.setLastValue(modAmp);
  }
  
  void setAmpAmp(float a){
    ampAmp = a;
    amp.amplitude.setLastValue(ampAmp);
  }

  void setCarF(float f)
  {
    carF = f;
    car.frequency.setLastValue( carF );
  }

  void setModOff(float f)  // Again, really the carrier frequency
  {
    modOff = f;
    mod.offset.setLastValue( modOff);
  }

  void bumpModOff(float change)  // Again, really the carrier frequency
  {
    modOff += change;
    mod.offset.setLastValue( modOff);
  }

  void setC2M(float r)    // Decided not to set things with C:M ratio, just display
  {
    // c2mRatio = modOff / modF;
    //modF = modOff / r;
  }

  void setIndex(float i)  // Decided not to set things with index, just display
  {
    // index = modAmp / modF
  }
  
  void toggleAMod(boolean bool){
    if(!bool) {
      amp.unpatch(car);
      car.setAmplitude(.6);
    }
    else amp.patch(car.amplitude);
  }
  
  void toggleFMod(boolean bool){
    if(!bool) {
      mod.unpatch(car);
      car.setFrequency(modOff);
      //car.setAmplitude(.6);
    }
    else mod.patch(car.frequency);
  }
  
  void stop()
  {
    car.unpatch(out);
  }
}