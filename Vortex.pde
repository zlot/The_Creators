//-------------------[Vortex]----
//

LinkedList<Vortex> vortexesQueue;
LinkedList<AttractionBehavior> behavioursQueue;
/* note: I have a concurrent behavioursQueue to take care of adding/removing behaviours as vortexes are created/destroyed.
        You would think a simplified process would be to add/remove the one attractionBehaviour variable per Vortex instance,
        however this wasn't working as great as expected -- sometimes the behaviour wouldn't be properly removed. This way works. */
        
void vortexSetup() {
  behavioursQueue = new LinkedList<AttractionBehavior>();
  vortexesQueue = new LinkedList<Vortex>();
  
  for (int i = 0; i < 5; i++)  //create 5 vortexes initially.
    vortexesQueue.offer(new Vortex()); // add to tail of queue.
}

class Vortex {
  AttractionBehavior attractionBehavior;
  InteractiveFrame iFrame_v;
  PVector vel; // controls the direction the vortex moves in (slowly). 
  int life = 0;
  float ageing = 1;// int(random(1, 4)); //lower is a faster age!
  int maxLife = 400;
  int speedChecker = 10;
  float diam = 480; // was 180.
  float grootteInc = .5;  // grootte == size
  
  int angle = 30;
  float sinAdd;
  Vec3D attractorPosition;
  
  Vortex() {
    iFrame_v = new InteractiveFrame(scene);
    setSize();
    setPositionV();
    setAttractionBehaviour();
  }

  /**** set size *****/
  public void setSize() {
    //sinAdd = sin(angle)*random(1, 1.5);
  }
  /***** set position *****/
  public void setPositionV() {
    float low = -1100;
    float high = 1100;
    iFrame_v.setPosition(new PVector(random(low, high), random(low, high), random(low, high)));
    vel = new PVector(random(-1,1),random(-1,1), random(-1,1));
  }  

  public PVector getPositionV() {
    return iFrame_v.position();
  }

  private void setAttractionBehaviour() {
    PVector positionV_ = iFrame_v.position();     
    attractorPosition = new Vec3D(positionV_.x, positionV_.y, positionV_.z);
    attractionBehavior = new AttractionBehavior(attractorPosition, diam*1.4, .27f, 0); 
    addBehaviour();
  }

  void addBehaviour() {
    behavioursQueue.offer(attractionBehavior);
    physics.addBehavior(attractionBehavior);
  } 
  void removeBehaviour() {
    physics.removeBehavior(behavioursQueue.poll()); // take out of behavioursQueue and remove from physics system.
  }

  public void draw(boolean showVortexes) {
    // grow in diameter in early stage of life
    if (life <= maxLife/2) { 
      diam += random(grootteInc);
    } else if (life > maxLife/2) {
      // shrink in diameter in later stage of life
      diam += random(-grootteInc);
    }
    
    if(frameCount % ageing == 0) {
      life++;
    }
  
    pushMatrix();
    pushStyle();
    // move the vortex.
    iFrame_v.translate(vel.x,vel.y,vel.z);
    PVector pvec = iFrame_v.position();
    attractorPosition.set(pvec.x, pvec.y, pvec.z);
    
    iFrame_v.applyTransformation();
    if(showVortexes) {
      strokeWeight(0.5);
      if(audioBang)
        noStroke(); // the drawing of vortex's is INCOMPLETE.
        //stroke(255, map(abs(noiseVal),0,1,0,25));
      else
        noStroke();
      sphere(diam);
    }
    
    popStyle();
    popMatrix();
    
    if (life >= maxLife) {
      die();
    }
  }
  void die() {
    removeBehaviour(); // remove all behaviours      
    vortexesQueue.poll(); // Retrieves and removes the head (first element) of this list. (offer() adds to tail)
  }
  
  
}
  
  
 

  

