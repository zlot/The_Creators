
class WireframePlanet {
  private final int GLOBEDETAIL = 16; // 16 or 32?
  private InteractiveFrame iFrame;
  // mesh class used to create the mesh and also to use subdivision methods
  private WETriangleMesh mesh;
  private Collection<Vertex> verticesList;
  boolean lookingAt = false; // flag when planet is being looked at but NOT when selected in world-view.
  float currentScale = 1; // scale of planet. When gets too big, destroy!
  float scaleInc; // increment the planet scales up from.
  int radius;
  PVector vel; // velocity of planet.
  private float sizeTooBig = random(1.2,1.7); // size of a planet when it decides to become a textured planet
  int fadeIn = 210; // 0-255 color scale. controls fade-in effect when planet is created. begins at 0 when created and ++'s to 210.
  private float rOffset = random(0.0005, 0.003);

 
  /* for particle attractor*/
  Vec3D attractorPosition = new Vec3D(0,0,0); // used to update position of attractor. use position.set().
  int attractorRadius;
  float strength;
  float jitterAtt;
  AttractionBehavior planetAttractor;  // attractor of particles
  AttractionBehavior planetAttractorNeg; // makes the particles sit on the outside of the planet.
  AttractionBehavior exploderBehavior;
  
  /***** CONSTRUCTORS *****/
  WireframePlanet() {
    radius = 50; // default.
    initInteractiveFrame(new PVector(random(-1300,1300),random(-1300,1300),random(-1300,1300)));
    initMesh(radius, GLOBEDETAIL);
    scaleInc = setScaleInc();
    sizeTooBig = setSizeTooBig();
    initPlanetAttractor();
    addToPlanetList();
    fadeIn = 20;
   // initPhysics();
  }
  WireframePlanet(PVector pos, int _radius) {
    initInteractiveFrame(pos);
    initMesh(_radius, GLOBEDETAIL);
    scaleInc = setScaleInc();
    sizeTooBig = setSizeTooBig();
    radius = _radius;
    initPlanetAttractor();
    addToPlanetList();
    fadeIn = 20;
   // initPhysics();
  }  
  
  /***** PLANET ATTRACTOR METHODS *****/
  void initPlanetAttractor() {
    int attractorRadius = radius*4;
    float strength = 0.5; // 0.15f
    float jitterAtt = 0;
    planetAttractor = new AttractionBehavior(attractorPosition, attractorRadius, strength, jitterAtt);
    planetAttractorNeg = new AttractionBehavior(attractorPosition, radius, -14, 0);
    addBehavior();
  }
  
  void addBehavior() {
    physics.addBehavior(planetAttractor);  
    physics.addBehavior(planetAttractorNeg);
  }
  /* occasionally update the neg behaviour to match the size of the planet */
  void updateAttNegBehavior() {
    physics.removeBehavior(planetAttractorNeg);
    planetAttractorNeg = new AttractionBehavior(attractorPosition, getRadius()*1.5, -6, 0);
    physics.addBehavior(planetAttractorNeg);
  }
  void explodeTheParticles() {
    physics.removeBehavior(planetAttractor);
    exploderBehavior = new AttractionBehavior(attractorPosition, getRadius(), -65, 0);
    physics.removeBehavior(exploderBehavior);
  }
  void removeAllBehaviors() {
    physics.removeBehavior(planetAttractor);
    physics.removeBehavior(planetAttractorNeg);
  }  
  /***** END PLANET ATTRACTOR METHODS *****/
  
  
///////////////////////
///////////////
//////////////////
  void initPhysics() {
    for (Vertex v : mesh.vertices.values()) {
        physics.addParticle(new VerletParticle(v));
    }
    // turn mesh edges into springs
    int inc = 0;
    for (WingedEdge e : mesh.edges.values()) {
      //if(inc % 16 == 0 ) {
        VerletParticle a = physics.particles.get(((WEVertex) e.a).id);
        VerletParticle b = physics.particles.get(((WEVertex) e.b).id);
        physics.addSpring(new VerletSpring(a, b, a.distanceTo(b), 1f));
      //}
      inc++;
    }
  }
/////////////////////////
  
  void updateAttractorPosition() {
    PVector pv = iFrame.position();
    attractorPosition.set(pv.x, pv.y, pv.z);  
  }
  
  float setScaleInc() {
    return random(0.0012, 0.0018);
  }
  float setSizeTooBig() {
    return random(1.8, 3.4); // as a scale
  }
  
  int addToPlanetList() {
    planetList.add(this);  // add to planetList
    return planetList.size()-1;
  }
  
  void initMesh(int radius, int globeDetail) {
    mesh = new WETriangleMesh();
    mesh.addMesh(new Sphere(radius).toMesh(globeDetail));
    updateVerticesList();
  }
  
  void initInteractiveFrame(PVector pos) {
    iFrame = new InteractiveFrame(scene);
    iFrame.setGrabsMouseThreshold(30);
    iFrame.setPosition(pos); // position in space
    vel = new PVector(random(-PLANET_SPEED,PLANET_SPEED),random(-PLANET_SPEED,PLANET_SPEED), random(-PLANET_SPEED,PLANET_SPEED));
  } 
  /* Convenience method */
  void setPosition(PVector pos) {
    iFrame.setPosition(pos);
  }  
  
  /***** DRAW METHOD *****/
  void draw(int planetNumber) {
    pushMatrix();
      iFrame.translate(vel.x,vel.y,vel.z);  // moves the planet.
      iFrame.applyTransformation();
      rotate(frameCount*rOffset);
////////////////
//      for (Vertex v : mesh.vertices.values()) {
 //         v.set(physics.particles.get(v.id));
//      }
////////////////
      if (iFrame.grabsMouse())
        stroke(255, 0, 0);
      else
        stroke(55,119,104,fadeIn);
      if(fadeIn < 210) fadeIn++; 
      gfx.mesh(mesh, false, 0); // mesh(mesh, smooth, normalLength)    
    popMatrix();
    jitterMesh(planetNumber);
    scaleMesh();
    updateAttractorPosition();
    if(frameCount % 180 == 0) {
      if(random(1) < 0.0) explodeTheParticles();
      updateAttNegBehavior();
    }
    updateVerticesList(); // always appear at the end. Needed to jitter mesh

    // if too big, turn into GPUPlanet, destroy
    if(currentScale >= sizeTooBig) {
      createGPUPlanet();
      destroy();
    }
  }
  void drawInteractiveFrame(int planetNumber) {
    pushMatrix();
      scene.interactiveFrame().setPosition(getPosition()); // probably dodgy - can be fixed
      scene.interactiveFrame().applyTransformation();
      pushStyle();
      if(!lookingAt) {
        stroke(255, 0, 0);
        fill(0,255,0);
      }
      gfx.mesh(mesh, false, 0); // mesh(mesh, smooth, normalLength) 
      popStyle();
    popMatrix();
    jitterMesh(planetNumber);
    updateVerticesList();
    // update lighting information
    //mesh.computeVertexNormals();
    // needed after any major vertex modification
    rebuildIndex();
    updateAttractorPosition();
  }
  
  WireframePlanet createGPUPlanet() {
    GPUPlanet2 temp = new GPUPlanet2(mesh, getPosition(), vel);
    return this;
  }
  
  WireframePlanet createEasterEgg() {
    GPUPlanet temp = new GPUPlanet(mesh, getPosition());
    return this;
  }
  
  /**** WHAT TO DO WHEN IT IS DESTROYED *****/
  void destroy() {
    // remove all behaviours
    removeAllBehaviors();
    // find what index this planet is and remove it
    int indexOf = planetList.indexOf(this); 
    planetList.remove(indexOf);
  }
  
  void updateVerticesList() {
    verticesList = mesh.getVertices();
  }
  
  void jitterMesh(int planetNumber) {
    for (Vec3D v : verticesList) {
      float r = random(1);
      ////// SHOULD ALL VERTICES MOVE OR JUST SOME? PLAY WITH THIS!
      if (r < 0.4) {
        float mappedF = map(planetNumber > freqs.length-1 ? freqs[round(random(0,freqs.length-1))] : freqs[planetNumber], 0, 1, 0, jitter);
        v.jitter(mappedF * (3.9*r)); // play with multiplier for more/less jitter
      }
    }
  }
   
  void scaleMesh() {
    mesh.scale(1+scaleInc);
    currentScale += scaleInc;
  }
 
  void smoothToxicLibsMesh() {
     new LaplacianSmooth().filter(mesh, 1);
    // update lighting information
    mesh.computeVertexNormals();
  }


  void setAsInteractiveFrame(boolean is) {
    selectedPlanet = this;
  }

  
  void rebuildIndex() {
    mesh.rebuildIndex();
  }
  
  void setLookingAt(boolean flag) {
    lookingAt = flag;  
  }
  
  void removeFromPlanetList() {
    planetList.remove(this);  
  }

  /***** ACCESSOR METHODS *****/
  WETriangleMesh getMesh() {
    return mesh;  
  }
  InteractiveFrame getFrame() {
    return iFrame;  
  }
  PVector getPosition() {
    return iFrame.position();  
  }
  float getRadius() {
    return radius*currentScale;  
  }  

}

