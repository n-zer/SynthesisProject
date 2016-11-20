/* Frequency Modulation Demo
 A simple example for doing FM (frequency modulation) using two Oscils. 
 Use the mouse to control the speed and range of the frequency modulation.
 Use the up and down arrows to control the carrier frequency (modulator offset).
 The display is a full-window real-time spectrum of the output
 to show the sidebands, along with FM parameters.
 
 Adapted by Al Biles from a Processing example by Damien Di Fede
 */

// Import everything necessary to make sound.
import ddf.minim.*;
import ddf.minim.ugens.*;     // Needed for the oscillators
import ddf.minim.analysis.*;  // Needed for the FFT

// Create all of the variables that will need to be accessed in
// more than one methods (setup(), draw(), stop()).
Minim minim;
AudioOutput outL;
AudioOutput outR;
FMInst fm1;        // Make an FM Instrument object
FMInst fm2;
FFT   fft;         // To draw the spectra
FFT fft2;
PFont legendFont;  // To show the FM parameters in real time
PFont scaleFont;

float carF;        // Not really used
float modF;        // Frequency for the modulating oscillator
float modAmp;      // Amplitude for the modulating oscillator
float modOff;      // Modulator offset, really the carrier frequency
boolean shiftOn = false;
int mouseAffect = 0;
boolean keyToggle = false;
boolean amp = true;
boolean fm = true;

final int RIGHTPAD = 200;

// setup is run once at the beginning
void setup()
{
  // Initialize the drawing window
  //size( 1600, 800);          // 2 pixels wide per frequency bin
  fullScreen();
  legendFont = createFont("Helvetica", 16);  // This works for standard fonts
  scaleFont = createFont("Helvetica", 10);  // This works for standard fonts

  // Initialize the minim and out objects
  minim = new Minim( this );
  outL = minim.getLineOut();
  outR = minim.getLineOut();
  //carF = 2000;     // Basically ignored
  modF = 300.0;      // Initial values will be overridden by user in real time
  modAmp = 2000.0;
  modOff = 300.0;    // Modulator offset is really the carrier freauency
  fm1 = new FMInst(modF, modAmp, modOff, -1, outL);  // Create the actual FM object
  fm2 = new FMInst(modF, modAmp, modOff, 1, outR);
  fft = new FFT( outL.bufferSize(), outL.sampleRate() );
  fft2 = new FFT( outR.bufferSize(), outR.sampleRate() );
}

// draw is run many times
void draw()
{
  // Maybe alter the carrier frequency (modulator offset) with arrow keys
  // Holding down shift key is 50X faster
  

  //if (keyPressed && key == 'm')  // Make Perlin-random movements in carF, modF, modA
   // fm1.move();
    
  if(keyPressed && key == 'm' && !keyToggle){
    keyToggle = true;
    mouseAffect = (mouseAffect+1) % 3;
  }
  else if(keyPressed && key == 'a' && !keyToggle){
    keyToggle = true;
    amp = !amp;
    fm1.toggleAMod(amp);
  }
  else if(keyPressed && key == 'f' && !keyToggle){
    keyToggle = true;
    fm = !fm;
    fm1.toggleFMod(fm);
  }
  else if(!keyPressed)
    keyToggle = false;

  // erase the window to black
  background( 0 );
  // draw using a white stroke
  stroke( 255 );

  textFont(legendFont);             // Set up and print the FM parameters
  fill(255);
  text("Carrier f: " + ((fm) ? fm1.modOff : fm1.carF), width-RIGHTPAD, 20);  // Mod offset really carrier f
  text("Mod freq: " + fm1.modF, width-RIGHTPAD, 40);
  text("Mod amp: " + fm1.modAmp, width-RIGHTPAD, 60);
  text("C:M Ratio: " + (fm1.modOff / fm1.modF), width-RIGHTPAD, 80);  
  text("Mod Index: " + (fm1.modAmp / fm1.modF), width-RIGHTPAD, 100);
  text("Amp freq: " + fm1.ampF, width-RIGHTPAD, 120);
  text("Amp amp: " + fm1.ampAmp, width-RIGHTPAD, 140);
  text("mouseX: Freq", width-RIGHTPAD, 170);
  text("mouseY: Depth", width-RIGHTPAD, 190);
  //text("m: Move Params", width-RIGHTPAD, 270);
  text("m: Toggle mouse params",width-RIGHTPAD, 210);
  if(mouseAffect ==0)
    text("mouse params: FM",width-RIGHTPAD,230);
  else if(mouseAffect ==1)
    text("mouse params: AM",width-RIGHTPAD,230);
  else if(mouseAffect ==2)
    text("mouse params: Carrier",width-RIGHTPAD,230);
  text("f: "+((fm)?"disable":"enable") + " FM", width-RIGHTPAD, 270);
  text("a: "+((amp)?"disable":"enable") + " AM", width-RIGHTPAD, 290);

  // draw the waveforms
  
  drawWaveform(height/8,height/8,outL);
  drawWaveform(5*height/8,height/8,outR);

  drawFFT(0, height/2,fft, outL);  
  drawFFT(height/2, height/2,fft2, outR); 
}

void drawWaveform(float y, float h, AudioOutput out){
  for ( int i = 0; i < out.bufferSize () - 1; i++ )
  {
    // find the x position of each buffer value
    float x1  =  map( i, 0, out.bufferSize(), 0, width-RIGHTPAD-20 );
    float x2  =  map( i+1, 0, out.bufferSize(), 0, width-RIGHTPAD-20 );
    // draw a line from one buffer position to the next for both channels
    stroke(0, 255, 0);
    line( x1, y + out.left.get(i)*h, x2, y + out.left.get(i+1)*h);
    //line( x1, 300 + out.right.get(i)*100, x2, 300 + out.right.get(i+1)*100);
  }
}

void drawFFT(float y, float h, FFT fourier, AudioOutput out){
  // Code for mapping fft to real-time spectrum
  fourier.forward(out.left);     // Display the spectra, mono => just need left
  textFont(scaleFont);       // Set up the font for the scale
  stroke(255);
  for (int i = 0; i < fourier.specSize (); i++)
  {
    // draw the line for frequency band i, scaling it by 3 so we can see it a bit better
    line(i*2, y + h*0.85, i*2, y + h*0.85 - fourier.getBand(i));
    if (i%16 == 0)
    {
      if (i%32 == 0)
      {
        line (i*2, y + h*0.85, i*2, y + h*0.85 + 10);
        text(int(fourier.indexToFreq(i)), i*2, y+h*0.85+19);
      } else
      {
        line (i*2, y+h*0.85, i*2, y+h*0.90 + 10);
        text(int(fourier.indexToFreq(i)), i*2, y+h*0.90+19);
      }
    }
  }
}

// we can change the parameters of the frequency modulation Oscil
// in real-time using the mouse.  Commented out code is earlier versions.
void mouseDragged()
{
  //carF = map( mouseX, 0, width, 0.1, 3000.0 );
  //modOff = map( mouseX, 0, width, 0.1, 3000.0 );
  //modF = ;
  //modF = map( mouseY, 0, height, 3000, 0.1 );
  //modAmp = ;
  //float c2M = map( mouseX, 0, width, 0.01, 20.0 );

  //fm1.setCarF( carF );
  //fm1.setModOff( modOff );

  // Moved above stuff into FMInst to modify modulator freq and amplitude
  if(mouseAffect == 0){
    fm1.setModF( map( mouseX, 0, width, 0.1, 3000.0 ) );
    fm1.setModAmp( map( mouseY, 0, height, 6000, 0.1 ) );
  }
  else if (mouseAffect ==1){
    fm1.setAmpF( map( mouseX, 0, width, 0.1, 3000.0 ) );
    fm1.setAmpAmp( map( mouseY, 0, height, 1.0, 0 ) );
  }
  else if(mouseAffect==2){
    fm1.setModOff(map( mouseX, 0, width, 0.1, 3000.0 ));
    fm1.setCarF(map( mouseX, 0, width, 0.1, 3000.0 ));
  }
  //else
  //  fm1.setCarF(map( mouseX, 0, width, 0.1, 3000.0 ));

  //fm1.setC2M( c2M );
}

void keyPressed()
{
  if (keyCode == SHIFT)
    shiftOn = true;
  if (key == 'q')
  {
    fm1.stop();
    //out.pauseNotes();
    exit();
  }
}

void keyReleased()
{
  if (keyCode == SHIFT)
    shiftOn = false;
}

void stop()         // Override the default stop() method to clean up audio
{
  outL.close();      // Close up all the sounds
  outR.close();
  minim.stop();     // Close up minim itself
  super.stop();     // Close up rest of program
}