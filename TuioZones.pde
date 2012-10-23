/*----------------------------------------------------------------
             Tuiozones to Tuio Translation    
                    B O U Y A H     
---------------------------------------------------------------- */
float tuioCursors = 0;
TUIOzoneCollection zones;
int [][] tuioCursorList = {{0, 0}, {0, 0}};
boolean scrunchToggle = false; // triggered true/false every time a scrunch in/out is made
boolean runScrunchOnce = true; // flag for making sure scrunch gesture is only recognized once.
boolean selectedAPlanetFlag = false; // flag when a planet is selected

boolean easterEgg = false;
int easterCounter = 0;
float tempAttractorRadius;

int tttimeout = 0; // triple tap timeout var
void tuioUpdate() {
  /*----------------- T R I P L E T A P -- 
  ------------------------------------*/

  /* timeout for triple tap feature */
  if(tripleTapCounter > 0) {
    tttimeout++;
    if(tttimeout > 29) {
      tripleTapCounter = 0;
      tttimeout = 0;
    }
  }
  
  tuioCursorList=zones.getPoints();

  /* custom listeners */
  if (tuioCursorList.length > tuioCursors) {
    addTuioCursor();
  } 
  else if (tuioCursorList.length < tuioCursors) {
    removeTuioCursor();
  }

  tuioCursors = tuioCursorList.length;

       if(scrunchToggle) {
        // allow zoom gesture to control size of attractor.
        tempAttractorRadius += map(tzScaleFactor,1f,2f,0f,10f);
        a.updateAttractorRadius(tempAttractorRadius);
      }
 
  
  switch (tuioCursorList.length) {
    case 1: {
      for (int i=0;i<tuioCursorList.length;i++) {
        tcurX = translateTuioX(tuioCursorList[i][0]);
        tcurY = translateTuioY(tuioCursorList[i][1]);
      }
      scrunch5Counter = 0;
      break;
    }
   
    case 3: {
      
       for(GPUPlanet2 p : GPUPlanetList2) {    
          // only check if tcur is over a planet if a planet has not already been selected.
          if(!selectedAPlanetFlag) {
            // check if tcur is grabbing a planet
            p.getFrame().checkIfGrabsMouse(tuioCursorList[0][0], tuioCursorList[0][1], scene.camera());
            if(p.getFrame().grabsMouse()) {
              // set the selected planet as the scene's interactive frame.
              p.setAsInteractiveFrame(true);
              scene.setDrawInteractiveFrame(true);
              selectedAPlanetFlag = true;
              withholdWireframeSelection = true;
            }  
            // once finished selecting a planet, reset flag to false.
            if(selectedGPUPlanet == null) {
              selectedAPlanetFlag = false;
              withholdWireframeSelection = false;
            } 
          }
       }
      
      if(!withholdWireframeSelection) {
         for(WireframePlanet p : planetList) {    
          // only check if tcur is over a planet if a planet has not already been selected.
          if(!selectedAPlanetFlag) {
            // check if tcur is grabbing a planet
            p.getFrame().checkIfGrabsMouse(tuioCursorList[0][0], tuioCursorList[0][1], scene.camera());
            if(p.getFrame().grabsMouse()) {
              // set the selected planet as the scene's interactive frame.
              p.setAsInteractiveFrame(true);
              scene.setDrawInteractiveFrame(true);
              selectedAPlanetFlag = true;
            }  
          } else {
            // once finished selecting a planet, reset flag to false.
            if(selectedPlanet == null) {
              selectedAPlanetFlag = false;
            } 
          }
        } 
      } 
      

    }
      scrunch5Counter = 0;
      break;
    case 4:
      scrunch5Counter = 0;
      break;
    /* ----------------------------------------------------
     SCRUNCH GESTURE
    /* ----------------------------------------------------*/
    case 5: {
      scrunch5Counter++;
      if(scrunch5Counter == 30 && runScrunchOnce) {
        scrunchToggle = !scrunchToggle;
        //attractorActive = true;
        a.toggleDrawInteractiveFrame(tuioCursorList[0][0], tuioCursorList[0][1]); // see Attractor class.
//        runAttractor();
        scrunch5Counter = 0;
        runScrunchOnce = false;
      } 
      
      totaal = 0;
      int scrunchNumber = 5;
      float[] distances = new float[scrunchNumber];
      for (int i = 0; i < scrunchNumber; i++) {
        if (i < scrunchNumber-2) {
          distances[i] = dist(tuioCursorList[i][0], tuioCursorList[i][1], tuioCursorList[i+1][0], tuioCursorList[i+1][1]);
        }
        if (i == scrunchNumber-1) {
          distances[scrunchNumber-1] = dist(tuioCursorList[i][0], tuioCursorList[i][1], tuioCursorList[0][0], tuioCursorList[0][1]);
        }
        totaal += distances[i];
      }
      average = totaal/scrunchNumber;
      float targetX = average;
      scrunch5 = (targetX - scrunch5)*easing;
      // initialise entry-point for 5 fingers to act as relative position for distance calculations
      if (scrunch5EntryPoint == true) {
        scrunch5_init = scrunch5;
        scrunch5EntryPoint = false;
      }
      scrunch5_dis = max(scrunch5_init, scrunch5) - min(scrunch5_init, scrunch5);
      if(scrunch5_dis >= 5.8 && scrunchToggle == false && runScrunchOnce == true) { // distance: between 8-9, tested on multitouch table
        scrunchToggle = true;
        runScrunchOnce = false;
        float avgX = 0;
        float avgY = 0;
        for(int i=0;i<tuioCursorList.length; i++) {
            avgX+=tuioCursorList[i][0];
            avgY+=tuioCursorList[i][1];
        }
        avgX /= 5;
        avgY /= 5;
        a.toggleDrawInteractiveFrame((int) avgX,(int) avgY); // see Attractor class.
      } else if(scrunch5_dis >= 6 && scrunchToggle == true && runScrunchOnce == true) {
        scrunchToggle = false;
        a.toggleDrawInteractiveFrame(0, 0);
        runScrunchOnce = false;
      }

      break;
    }
    
    case 31: {
      easterCounter++;
      if (easterCounter >= 50) {
        easterEgg = true;
      }
      break;
    }
    
    case 32: {
      easterCounter++;
      if (easterCounter >= 50) {
        easterEgg = true;
      }
      break;
    }

      
    default: {  
      totaal = 0;
      average = 0; 
      scrunch5_dis = 0;
    }
    
  }
  
  // if attractor mode is enabled, move the attractor! See attractor class
  if(attractorMode) a.moveAttractor(tcurX, tcurY);

  gesturesChecker(); 
}

int scrunch5Counter = 0;
boolean withholdWireframeSelection = false;


PVector lastPosition = new PVector(0, 0);
PVector newPosition = new PVector(0, 0);

int tripleTapCounter = 0;
void addTuioCursor() {
  if (tuioCursorList.length == 5) {
    scrunch5EntryPoint = true;
  }

  //-------------------------------------------[START NECESSARY FOR TRIPLETAP]
     
  newPosition = new PVector(tuioCursorList[tuioCursorList.length-1][0], tuioCursorList[tuioCursorList.length-1][1]);

  if(dist(lastPosition.x, lastPosition.y, newPosition.x, newPosition.y) <= 16 && lastPosition.x != 0) {
    tripleTapCounter++; 
    if(tripleTapCounter == 2) { // 2 because of the way this method is setup. Just trust me.
      tripleTap();
      tripleTapCounter = 0;
      lastPosition = new PVector(0, 0);
      newPosition = new PVector(0, 0);
    }
  }
  
  lastPosition = new PVector(tuioCursorList[tuioCursorList.length-1][0], tuioCursorList[tuioCursorList.length-1][1]);
     
 //-------------------------------------------[END NECESSARY FOR TRIPLETAP]
}


/* run when tripleTap gesture is made */
void tripleTap() {
  tuioHandler.getTuioDevice().setCameraMode(HIDevice.CameraMode.GOOGLE_EARTH);
  scene.camera().interpolateTo(defaultSceneView.getFrame(), 3);
  //scene.camera().lookAt( scene.camera().sceneCenter() );
  selectedAPlanetFlag = false;
  scene.setDrawInteractiveFrame(false);  
}


void removeTuioCursor() {  
  
  if (tuioCursorList.length == 5) {
    scrunch5EntryPoint = true;
  }
  tcurYforZ = 0;
  runScrunchOnce = true; // flag scrunch gesture that it can be activated again (see switch 5 in tuioUpdate() )
  // interpolate camera to zoom in on selected planet
  if(selectedAPlanetFlag && selectedPlanet != null) {
    scene.camera().fitSphere(selectedPlanet.getPosition(), 700);
    selectedPlanet.setLookingAt(true);
  }
  // interpolate camera to zoom in on selectedGPUplanet
  if(selectedAPlanetFlag && selectedGPUPlanet != null) {
    scene.camera().fitSphere(selectedGPUPlanet.getPosition(), 1000);
    //selectedGPUPlanet.setLookingAt(true);
  }
}





// have to translate so 0,0 is middle of canvas 
int translateTuioX(float x) {
  return (int) map(x, 0, width, -width/2, width/2);
}
int translateTuioY(float y) {
  return (int) map(y, 0, height, -height/2, height/2);
}



/**
 * Singleton class that holds a scene frame in a particular position which becomes the default
 * camera view when triple-tap gesture is used. Must use this instead of showEntireScene() because
 * that will zoom out even of the worldSphere boundary.
 */
class DefaultSceneView {
  InteractiveFrame iFrame;
  
  DefaultSceneView() {
    iFrame = new InteractiveFrame(scene);
    setPosition();
  }
  /***** set position *****/
  public void setPosition() {
    iFrame.setPosition(new PVector(0,0,4800));
  }  
  public InteractiveFrame getFrame() {
    return iFrame;
  }
}


