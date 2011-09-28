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

void tuioUpdate() {
  /*----------------- D O U B L E T A P -- 
  PVector locationDoubletap = location
  boolean doubletap = gesture
  ------------------------------------*/
  newTuioCounter++;
  if(newTuioCounter >= 100){
    lastPosition = newPosition = new PVector(0, 0, 0);
  }  
  
  tuioCursorList=zones.getPoints();
  
  if (tuioCursorList.length > tuioCursors) {
    addTuioCursor();
  } 
  else if (tuioCursorList.length < tuioCursors) {
    removeTuioCursor();
  }
  tuioCursors = tuioCursorList.length;

///******* WORKING ON THIS *////////////
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
      break;
    }
   
    case 3: {
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
      break;
    case 4:
      break;
    /* ----------------------------------------------------
     SCRUNCH GESTURE
    /* ----------------------------------------------------*/
    case 5: {
      totaal = 0;
      int scrunchNumber = 5;
      float[] distances = new float[scrunchNumber];
      for (int i = 0; i < scrunchNumber; i++) {
        if (i < scrunchNumber-1) {
          distances[i] = dist(tuioCursorList[i][0], tuioCursorList[i][1], tuioCursorList[i+1][0], tuioCursorList[i+1][1]);
        }
        if (i == scrunchNumber-1) {
          distances[scrunchNumber-1] = dist(tuioCursorList[i][0], tuioCursorList[i][1], tuioCursorList[0][0], tuioCursorList[0][1]);
        }
        totaal += distances[i];
      }
      average = totaal/scrunchNumber;
      float targetX = average;
      scrunch5 += (targetX - scrunch5)*easing;
  
      if (scrunch5b == true) {
        scrunch5_init = scrunch5;
        scrunch5b = false;
      }
      scrunch5_dis = max(scrunch5_init, scrunch5) - min(scrunch5_init, scrunch5);
      
      if(scrunch5_dis >= 2 && scrunchToggle == false && runScrunchOnce == true) {
        scrunchToggle = true;
        runScrunchOnce = false;
        a.toggleDrawInteractiveFrame(); // see Attractor class.
      } else if(scrunch5_dis >= 2 && scrunchToggle == true && runScrunchOnce == true) {
        scrunchToggle = false;
        a.toggleDrawInteractiveFrame();
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







void addTuioCursor() {
  if (tuioCursorList.length == 5) {
    scrunch5b = true;
  }

  //-------------------------------------------[START NECESSARY FOR DOUBLETAP]
  tuioCursorList=zones.getPoints(); //i know i allready loaded it somewhere else, but it's necessary to update it here
   
  if (newTuioCounter <= 5){
    lastPosition = new PVector(tuioCursorList[tuioCursorList.length-1][0], tuioCursorList[tuioCursorList.length-1][1]);
  } else {
    newPosition = new PVector(tuioCursorList[tuioCursorList.length-1][0], tuioCursorList[tuioCursorList.length-1][1]);
  }

  if (dist(lastPosition.x, lastPosition.y, newPosition.x, newPosition.y) <= 40 && lastPosition.x != 0) {
    doubleTap();
    locationDoubleTap = new PVector(lastPosition.x, lastPosition.y);
    lastPosition = new PVector(0, 0);
    newPosition = new PVector(0, 0);
  }

 newTuioCounter = 0;
     
 //-------------------------------------------[END NECESSARY FOR DOUBLETAP]

}

/* run when doubleTap gesture is made */
void doubleTap() {
  tuioHandler.getTuioDevice().setCameraMode(HIDevice.CameraMode.GOOGLE_EARTH);
  //scene.camera().setPosition(new PVector(11080,0,0));
  
  //scene.camera().interpolateTo(planetList.get(0).getFrame());
  scene.camera().interpolateTo(defaultSceneView.getFrame());
  //scene.camera().lookAt( scene.camera().sceneCenter() );
  selectedAPlanetFlag = false;
  scene.setDrawInteractiveFrame(false);  
}


void removeTuioCursor() {
  if (tuioCursorList.length == 5) {
    scrunch5b = true;
  }
  tcurYforZ = 0;
  runScrunchOnce = true; // flag scrunch gesture that it can be activated again (see switch 5 in tuioUpdate() )
  if(selectedAPlanetFlag && selectedPlanet != null) {
    scene.camera().fitSphere(selectedPlanet.getPosition(), 700);
    selectedPlanet.setLookingAt(true);
  }
  
}

int newTuioCounter;
PVector lastPosition = new PVector(0, 0);
PVector newPosition = new PVector(0, 0);
PVector locationDoubleTap;




// have to translate so 0,0 is middle of canvas 
int translateTuioX(float x) {
  return (int) map(x, 0, width, -width/2, width/2);
}
int translateTuioY(float y) {
  return (int) map(y, 0, height, -height/2, height/2);
}



/**
 * Singleton class that holds a scene frame in a particular position which becomes the default
 * camera view when double-tap gesture is used. Must use this instead of showEntireScene() because
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


