/***** gui specific variables *****/
PMatrix3D currCameraMatrix;
PGraphics3D g3; 

PImage gestureImage;
PImage startImage;

/*-----
Area to draw on the screen, on top of the 3d space that Proscene basically handles
http://forum.processing.org/topic/proscene-and-2d-drawing
-----*/
void gui() {
  pushStyle();
  // Disable depth test to draw 2d on top
  hint(DISABLE_DEPTH_TEST);
  currCameraMatrix = new PMatrix3D(g3.modelview);
  // Since proscene handles the projection in a slightly different manner
  // we set the camera to Processing default values before calling camera():
  float cameraZ = ((height/2.0) / tan(PI*60.0/360.0));
  perspective(PI/3.0, scene.camera().aspectRatio(), cameraZ/10.0, cameraZ*10.0);
  camera();
  /*------  DRAW ON SCREEN BEGIN (put functions in here)  -----*/
  //drawGestures();     // see TUIO tab
  //drawTuioZoneCursors();
  
  if(PLAY_BEGINNING && frameCount < 450) drawIntroImages(); // play beginning.  
  
  if(intro)trail();  // DO NOT DELETE THIS !!!! FOR DRAWING BACKGROUND INTRO

  /*------  DRAW ON SCREEN END  -----*/
  g3.camera = currCameraMatrix;
  // Re-enble depth test
  hint(ENABLE_DEPTH_TEST);
  popStyle();
}

void drawIntroImages() {
  if(frameCount < 350) {
    pushMatrix();
    scale((float)(screen.width)/2130); // 2130 being w dimension of image
    image(gestureImage, 0, 0);
    popMatrix();
  }
  if(frameCount < 120) {
    pushMatrix();
    scale((float)(screen.width)/2130); // 2130 being w dimension of image
    image(startImage, 0, 0);
    popMatrix();
  }
  if (frameCount >= 360 && frameCount <= 400) {
    gestureImage = null;
    startImage = null;  
  }  
}





