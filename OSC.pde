boolean audioBang = false;
boolean printO = false;
float peak;
float scaleAudio = 10;

float[] freqs = new float[7];

void oscEvent(OscMessage theOscMessage) {
  /* check if theOscMessage has the address pattern we are looking for. */
 if (theOscMessage.checkAddrPattern("audioBang") == true) {
    if(theOscMessage.checkTypetag("f")) {
      if (theOscMessage.get(0).floatValue() == 1.0) {
        audioBang = true;
      } 
        
    }
 } 
  if(theOscMessage.checkAddrPattern("array") == true) {
       for (int i = 0; i <= 6; i++) {
         freqs[i] = theOscMessage.get(i).floatValue();
       }
  } 
 
  /*
   if (printO == true) {   
    println("### received an osc message. with address pattern "+theOscMessage.addrPattern() +
    " || " + theOscMessage.addrPattern() +" = " + theOscMessage.get(0).floatValue() );
  }
  */
  
  if(theOscMessage.checkAddrPattern("peak") == true) {
       for (int i = 0; i <= 6; i++) {
         peak = theOscMessage.get(0).floatValue()*scaleAudio*(scaleAudio/9);
       }
  }  
}

/* function to run if theres a new peak value in audio */
void bang() {
 if (audioBang == true) {
    background(9);
    audioBang = false;
    //planet = new WireframePlanet();
    //smoothAllMeshes();
  }
}


void smoothAllMeshes() {
  for(WireframePlanet p : planetList)
    p.smoothToxicLibsMesh();
}
