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
FMInst activeInst;
FFT   fft;         // To draw the spectra
FFT fft2;
PFont legendFont;  // To show the FM parameters in real time
PFont scaleFont;
PFont controlFont;

float carF;        // Not really used
float modF;        // Frequency for the modulating oscillator
float modAmp;      // Amplitude for the modulating oscillator
float modOff;      // Modulator offset, really the carrier frequency
boolean shiftOn = false;
int mouseAffect = 2;
boolean keyToggle = false;
boolean instrument = false;

final int RIGHTPAD = 200;

// setup is run once at the beginning
void setup()
{
  // Initialize the drawing window
  size( 1600, 800);          // 2 pixels wide per frequency bin
  //fullScreen();
  legendFont = createFont("Helvetica", 16);  // This works for standard fonts
  scaleFont = createFont("Helvetica", 10);  // This works for standard fonts
  controlFont = createFont("Helvetica",32);

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
  activeInst = fm1;
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
    activeInst.toggleAMod();
  }
  else if(keyPressed && key == 'f' && !keyToggle){
    keyToggle = true;
    activeInst.toggleFMod();
  }
  else if(keyPressed && key == 'o' && !keyToggle){
    keyToggle = true;
    instrument = !instrument;
    activeInst = (instrument)?fm2 : fm1;
  }
  else if(!keyPressed)
    keyToggle = false;

  // erase the window to black
  background( 0 );
  stroke(0);
  if(!instrument)
  {
    fill(0,0,10);
    rect(0,0,width-RIGHTPAD-20,height/2);
  }
  else {
    fill(10,0,0);
    rect(0,height/2,width-RIGHTPAD-20,height/2);
  }
  // draw using a white stroke
  stroke( 255 );

  textAlign(LEFT,BOTTOM);
  textFont(legendFont);             // Set up and print the FM parameters
  fill(255);
  text("Carrier f: " + ((activeInst.fmEnabled) ? activeInst.modOff : activeInst.carF), width-RIGHTPAD, 20);  // Mod offset really carrier f
  text("Mod freq: " + activeInst.modF, width-RIGHTPAD, 40);
  text("Mod amp: " + activeInst.modAmp, width-RIGHTPAD, 60);
  text("C:M Ratio: " + (activeInst.modOff / activeInst.modF), width-RIGHTPAD, 80);  
  text("Mod Index: " + (activeInst.modAmp / activeInst.modF), width-RIGHTPAD, 100);
  text("Amp freq: " + activeInst.ampF, width-RIGHTPAD, 120);
  text("Amp amp: " + activeInst.ampAmp, width-RIGHTPAD, 140);
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
  text("f: "+((activeInst.fmEnabled)?"disable":"enable") + " FM", width-RIGHTPAD, 270);
  text("a: "+((activeInst.ampEnabled)?"disable":"enable") + " AM", width-RIGHTPAD, 290);
  text("o: switch instrument",width-RIGHTPAD, 330);

  // draw the waveforms
  
  drawWaveform(height/8,height/8,outL);
  drawWaveform(5*height/8,height/8,outR);

  drawFFT(0, height/2,fft, outL);  
  drawFFT(height/2, height/2,fft2, outR); 
  
  
  textAlign(CENTER,CENTER);
  if(mouseAffect==0){
    float x = map(activeInst.modF,0.1,3000.0,0,width);
    float y = map(activeInst.modAmp,6000.0,0.1,0,height);
    fill(255,0,0);
    stroke(0);
    //textFont(legendFont);
    //ellipse(x,y,30,30);
    textFont(controlFont);
    text("FM",x,y);
  }
  else if(mouseAffect==1){
    float x = map(activeInst.ampF,0.1,3000.0,0,width);
    float y = map(activeInst.ampAmp,1.0,0,0,height);
    fill(0,255,0);
    stroke(0);
    textFont(controlFont);
    text("AM",x,y);
    //ellipse(x,y,30,30);
  }
  else if(mouseAffect==2){
    float x = map(activeInst.carF,0.1,3000.0,0,width);
    //float y = map(activeInst.modAmp,6000.0,0.1,0,height);
    //fill(50,0,0);
    //ellipse(x,y,30,30);
    fill(255);
    stroke(255);
    if(x>width-RIGHTPAD)
      textAlign(RIGHT,CENTER);
    else
      textAlign(LEFT,CENTER);  
    line(x,0,x,height);
    textFont(controlFont);
    text("Carrier freq",x,height/2);
  }
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
    activeInst.setModF( map( mouseX, 0, width, 0.1, 3000.0 ) );
    activeInst.setModAmp( map( mouseY, 0, height, 6000, 0.1 ) );
  }
  else if (mouseAffect ==1){
    activeInst.setAmpF( map( mouseX, 0, width, 0.1, 3000.0 ) );
    activeInst.setAmpAmp( map( mouseY, 0, height, 1.0, 0 ) );
  }
  else if(mouseAffect==2){
    activeInst.setModOff(map( mouseX, 0, width, 0.1, 3000.0 ));
    activeInst.setCarF(map( mouseX, 0, width, 0.1, 3000.0 ));
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