/* note: initiate this in setup! */

class TuioHandler {
  
  TuioProcessing tuioClient;
  HIDevice dev;
  final int TUIO_RADIUS = 50;  
  private HIDevice tuioDevice;
  int x = 0;
  int y = 0;
  int z = 0;  
  
  TuioHandler() {
    tuioClient = new TuioProcessing(ProcessingCanvas);
    tuioDevice = new HIDevice(scene, HIDevice.Mode.ABSOLUTE); // WILL BE REMOVED AT createAbsoluteHandler(). Just here to please the first removeHandler();    
    createRelativeHandler();
    addHandlerToScene();
  }  
  
  void removeHandler() {
    tuioDevice.removeHandler();  
  }
  void createAbsoluteHandler() {
    removeHandler();
    tuioDevice = new HIDevice(scene, HIDevice.Mode.ABSOLUTE);
    setSensitivity(new float[] {2f,2f,2f}, new float[] {0.0015, 0.0015, 0.0015});
    addHandlerToScene();
  }
  void createRelativeHandler() {
    removeHandler();
    tuioDevice = new HIDevice(scene, HIDevice.Mode.RELATIVE);
    setSensitivity(new float[] {-0.41f, -0.41f, 0.55f}, new float[] {0.00002f, 0.00002f, 0.000004f}); 
    addHandlerToScene();  
  }
  void addHandlerToScene() {
    tuioDevice.addHandler(ProcessingCanvas, "tuioFeed");
    setCameraMode();
    scene.addDevice(tuioDevice); 
  }
    
  void setSensitivity(float[] tsensitivity, float[] rotsensitivity) {
    tuioDevice.setTranslationSensitivity(tsensitivity[0], tsensitivity[1], tsensitivity[2]);
    tuioDevice.setRotationSensitivity(rotsensitivity[0], rotsensitivity[1], rotsensitivity[2]);
  }  
  void setCameraMode() {
    tuioDevice.setCameraMode(HIDevice.CameraMode.GOOGLE_EARTH);
  }

  /***** ACCESSOR METHODS *****/
  Vector getCursorList() {
    return tuioClient.getTuioCursors(); 
  }
  HIDevice getTuioDevice() {
    return tuioDevice;
  }
  TuioProcessing getTuioClient() {
    return tuioClient;  
  }
}



/* Not used anywhere except in convertScreenToWorld(), and never changes value (always (0,0,0)). */
PVector prevTcur = new PVector(0,0,0);
/**
 * Takes a cursor (from 2d screen realm) and returns the point converted to a point in the world.
 * PVector eventPoint the position of cursor
 */
public PVector convertScreenToWorld(PVector eventPoint) { // taken from InteractiveFrame mouseDragged(). PVector eventPoint is from the screen (2D plane).
  int deltaY = 0;
  deltaY = (int) (prevTcur.y - eventPoint.y);
  Point delta = new Point((eventPoint.x - prevTcur.x), deltaY);
  PVector worldEventPoint = new PVector((int) delta.getX(), (int) -delta.getY(), 0.0f);
  // Scale to fit the screen mouse displacement
  worldEventPoint.mult(2.0f * tan(scene.camera().fieldOfView() / 2.0f)
     * abs((scene.camera().frame().coordinatesOf(scene.interactiveFrame().position())).z) / scene.camera().screenHeight());
  // Transform to world coordinate system.
  worldEventPoint = scene.camera().frame().orientation().rotate(PVector.mult(worldEventPoint, 1/*translationSensitivity()*/)); 
  
  //scene.interactiveFrame().translate(trans); // this is what the library uses.
  return worldEventPoint;
}

float zoom = 0;
public void tuioFeed(HIDevice tuioDevice) {
  zoom = map(tzScaleFactor, 0, 2, -1000, 400);
  if(zoom == -300) zoom = 0; // cheap & easy way to get -1000 (faster zooming out) + having initial 0zoom at beginning)
  
   // if focusing on selected planet, change style of feed to rotate planet.
   if(scene.interactiveFrameIsDrawn()) {
     tuioDevice.feedTranslation(0,0,0);
     tuioDevice.feedRotation(tcurX, tcurY, zoom); 
   } else {
     tuioDevice.feedTranslation(tcurX, tcurY, zoom);
     tuioDevice.feedRotation(0,0,0);
   }
}
