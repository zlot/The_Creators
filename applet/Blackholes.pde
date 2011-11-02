
BlackHole blackHoleOut;
BlackHole blackHoleIn;

void blackHoleSetup() {
  blackHoleIn = new BlackHole();
  blackHoleOut = new BlackHole(200, -1f);
}

class BlackHole {
  float sketchSize = WORLD_RADIUS/10;  // or 10? 
  InteractiveFrame iFrame;
  PVector vel = new PVector(0,0,0);
  PVector acc = new PVector(-0.0001, 0.01, 0.0000001);
  Vec3D position = new Vec3D(0,0,0); // used to update position of attractor. use position.set().
  int attractorRadius = 900;
  float strength = 5.5;
  float jitter = 0;
  float topSpeed = 1;
  AttractionBehavior blackholeAttractor;
  TriangleMesh whiteBlackHole = (TriangleMesh) new Sphere(40).toMesh(2);
  
  /***** CONSTRUCTORS *****/
  // default constructor, creates sucky black hole.
  BlackHole() {
    initInteractiveFrame();
    blackholeAttractor = new AttractionBehavior(position, attractorRadius, strength, jitter);
    addBehavior();
  }
  BlackHole(int _attractorRadius, float _strength) {
    initInteractiveFrame();
    attractorRadius = _attractorRadius;
    strength = _strength;
    blackholeAttractor = new AttractionBehavior(position, attractorRadius, strength, jitter);
    addBehavior();
  }    
  
  void initInteractiveFrame() {
    iFrame = new InteractiveFrame(scene);
    iFrame.setPosition(randomPVector()); // sets random position of black hole.
  }  

  void draw() {
    pushMatrix();
    pushStyle();
    noStroke();
    iFrame.applyTransformation(); // makes it appear wherever tuiocursor is (but initial cursor still becomes origin?!)
    // if strength positive, sucks. if negative, blows
    if(strength > 0) {
      fill(0);
      sphere(100);
    } else {
      // superEllipsoid slows down framerate by about 10fps!
      //draw reactive black hole
      fill(map(peak,0,5,140,255),map(peak,0,5,0,100));
      scale(constrain(peak,0,1.7));
      gfx.mesh(whiteBlackHole, true, 40);        
    }
    popStyle();
    popMatrix();
    updatePosition();
  } 
  
  
  void updatePosition() {
    acc.set(random(-1, 1), random(-1, 1), random(-1, 1));
    acc.normalize();
    acc.mult(random(0.1)); 
    vel.add(acc);
    vel.limit(topSpeed);
    addToPosition(vel);
    
    //position.set(getPositionAsVec3D()); // update position for attractor behaviour
    PVector pv = iFrame.position();
    position.set(pv.x, pv.y, pv.z);
  }
  void addToPosition(PVector posAddition) {
    PVector newPosition = getPosition();
    newPosition.add(posAddition);
    iFrame.setPosition(newPosition);
  }
  
  void setPosition(PVector pos) {
    iFrame.setPosition(pos); 
  }  
  void addBehavior() {
    physics.addBehavior(blackholeAttractor);  
  }  
  void removeBehavior() {
    physics.removeBehavior(blackholeAttractor);  
  }  
  
  PVector randomPVector() {
    return new PVector(random(-sketchSize, sketchSize), random(-sketchSize, sketchSize), random(-sketchSize, sketchSize));
  }
  
  PVector getPosition() {
    return iFrame.position();
  }
  /* needed for VerletPhysics */
  Vec3D getPositionAsVec3D() {
    PVector pv = iFrame.position();
    return new Vec3D(pv.x,pv.y,pv.z);
  }    
}



/*
void superEllipsoidF(float n1, float n2, float n3, float n4, float n5, float n6, float n7, float n8, float peak_) {
  //SurfaceFunction functor=new SuperEllipsoid(abs(map(peak_, n1, n2, n3, n4)), abs(map(peak_, n5, n6, n7, n8)));
  //SurfaceMeshBuilder b = new SurfaceMeshBuilder(functor);
  //mesh = (TriangleMesh)b.createMesh(null,80,40);
  pushStyle();

  fill(255);
  noStroke();
 // stroke(255);
//  }
  mesh = (TriangleMesh) new Sphere(40).toMesh(2);
  
  scale(constrain(peak_,0,1));
  gfx.mesh(mesh, true, 0);
  
    //Ray3D(ReadonlyVec3D origin, ReadonlyVec3D direction) 
  //gfx.ray(new Ray3D(-500,0,500, new Vec3D(0,500,0)), 500);
  popStyle();
}
  
*/
