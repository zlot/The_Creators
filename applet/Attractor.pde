boolean attractorMode = false;
boolean attractorEnabled = false;

class Attractor {
  
  InteractiveFrame iFrame;
  AttractionBehavior attractionBehavior;
  Vec3D attractorPosition = new Vec3D(0,0,0);
  int attractorRadius = 900; //radius of attractor
  float strength = 9;
  float jitter = 0.00001f;
  PVector oldPosition;
  float rotatorInc = 0;
  
  
  /***** CONSTRUCTOR *****/
  Attractor() {
    iFrame = new InteractiveFrame(scene);
    attractionBehavior = new AttractionBehavior(attractorPosition, attractorRadius, strength, jitter);
  }  
   
  void addBehavior() {
    physics.addBehavior(attractionBehavior);
    tempAttractorRadius = attractorRadius; // tempAttractorRadius is a global. For allowing the attractor to expand/shrink when being used.
  }  
  
  void removeBehavior() {
    physics.removeBehavior(attractionBehavior);  
  } 
  
  PVector getPosition() {
    return iFrame.position();
  }
  void setPosition(PVector pos) {
    iFrame.setPosition(pos);
  }
  
  private void updateAttractorPosition() {
    PVector pvec = getPosition();
    attractorPosition.set(pvec.x, pvec.y, pvec.z);
  }
  void updateAttractorRadius(float r) {
    attractionBehavior.setRadius(r);
  }

  
  void draw() {
    pushMatrix();
    pushStyle();
    scene.interactiveFrame().applyTransformation(); // makes it appear wherever tuiocursor is (but initial cursor still becomes origin?!)
    noFill();
    stroke(255,255,255,100);
    rotateX(radians(rotatorInc));rotateY(radians(rotatorInc));rotateZ(radians(rotatorInc));
    sphere(tempAttractorRadius);
    popStyle();
    popMatrix(); 
    
    if(oldPosition != getPosition()) {
      updateAttractorPosition();
    }
    
    oldPosition = getPosition();
    rotatorInc += 0.14f;   
  } 
  
  void moveAttractor(int tcurX, int tcurY) {
    // convert cursor position to world coords, and then set the interactive frame to this world position.
    scene.interactiveFrame().setPosition(convertScreenToWorld(new PVector(tcurX,tcurY,0)));
    // now that interactiveFrame is correct, update position of iFrame to the same.
    iFrame.setPosition(scene.interactiveFrame().position());
  }  

  /* draw the attractor & activate behaviour if scruch gesture has been performed. See TuioZones tab */
  void toggleDrawInteractiveFrame(int tcurX, int tcurY) {
    scene.setDrawInteractiveFrame(true); // turn on interactiveFrame manipulation
    attractorEnabled = !attractorEnabled;
    attractorMode = !attractorMode;
    if(attractorEnabled) {
    moveAttractor(tcurX, tcurY);
      a.addBehavior();
    } else {
      a.removeBehavior(); 
      // if have enough particles, make a planet at this position
      planet = new WireframePlanet(a.getPosition(), NEW_WIREFRAME_RADIUS);
      scene.setDrawInteractiveFrame(false);
    }
  }
}

