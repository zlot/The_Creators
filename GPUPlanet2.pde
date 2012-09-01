/***** THIS PLANET CREATES THE PLANET EXACTLY LIKE THE SHAPE OF THE MESH *****/
int planetPhysicsMapCounter = 0; // needed to keep track of hashmaps of planets!

class GPUPlanet2 {  
  private InteractiveFrame iFrame;
  private WETriangleMesh mesh;
  private GLModel model;
  //////////////note::: globeDetail not used??
  private int globeDetail = 32; // dynamically create this? 32 or 60? has a BIG important impact. Final detail of texturedglobe!
  private int initWidth = 10; 
  private int age = 0; // age
/////////////  
  private int die;
  private PVector vel; // controls planet movement
  private float rOffset = random(0.0001, 0.015); // rotation offset
  float[] verts; // flattened array of vertices from toxiclibs mesh
  int hashId; 
  VerletPhysics planetPhysics;
  int altPlanetType; // EITHER 0 OR 1. If 0, planet gets springs, explodes well, doesn't get super-big, stays round shape.
  
  GPUPlanet2(WETriangleMesh _mesh, PVector position, PVector _vel) {
    initInteractiveFrame(position);
    mesh = _mesh;
    createPlanet(mesh);
    vel = _vel;
    GPUPlanetList2.add(this); // add to planet list.
    altPlanetType = round(random(0,1)-0.13); // weighted towards 0.
    //if altPlanetType is 0, then it lives longer.
    if(altPlanetType == 0) {
      die = round(random(1300,1900));
    } else { // altPlanetType is 1
      die = round(random(900,1400));
    }
  }
  
  void initInteractiveFrame(PVector position) {
    iFrame = new InteractiveFrame(scene);
    iFrame.setGrabsMouseThreshold(30);
    iFrame.setPosition(position);
  }  

  void createPlanet(WETriangleMesh mesh) {
    mesh.rebuildIndex();
    mesh.computeFaceNormals();
    // get flattened vertex & norms array (for processing in GL)
    verts = mesh.getMeshAsVertexArray();
    float[] norms=mesh.getVertexNormalsAsArray();

    model = new GLModel(ProcessingCanvas, vertices.size(), TRIANGLES, GLModel.STREAM);

    model.beginUpdateVertices();
    // in the array each vertex has 4 entries (XYZ + 1 spacing(W))
    for (int i = 0; i < verts.length/4; i++) {
      model.updateVertex(i, verts[4 * i], verts[4 * i + 1], verts[4 * i + 2]);
    }
    model.endUpdateVertices();      
   

    model.initTextures(1);
    model.setTexture(0, loadedTextures.get(round(random(0,loadedTextures.size()-1))));
    model.updateTexCoords(0, texCoords); // texCoords courtesy of calcSphereCoords(), run in setup() last in prep for these planets! 

    model.initNormals();
    model.beginUpdateNormals();
      for (int i = 0; i < verts.length/4; i++) model.updateNormal(i, norms[4 * i], norms[4 * i + 1], norms[4 * i + 2]);
    model.endUpdateNormals();
    
    model.initColors();
    model.beginUpdateColors();
    for (int i = 0; i < verts.length/4; i++) model.updateColor(i, 255, 255, 255, 0);
    model.endUpdateColors(); 
    
    // colour on dark side of planets
    model.setEmission(33,100);

    //model.setReflection(color(0,0,255), 255) ;

    // Setting model shininess.
    // TODO: try setting other parameters on the model here!
    //model.setShininess(3);
    
    initPhysics(mesh);
  }
  
//////////////////////// 
ArrayList<Vec3D> vec3DList;
ArrayList<VerletParticle> particleList;

  void initPhysics(WETriangleMesh mesh) {
    Vec3D vertPos;
    vec3DList = new ArrayList<Vec3D>();
///////////    
    particleList = new ArrayList<VerletParticle>();
    planetPhysics = new VerletPhysics();
    planetPhysics.setDrag(PARTICLE_DRAG);  
    
    // for each vert of this planet, create a corresponding particle in planetPhysics 
    for (int i = 0; i < verts.length/4; i++) {
      vertPos = new Vec3D(verts[4 * i], verts[4 * i + 1], verts[4 * i + 2]);
      vec3DList.add(vertPos);
      VerletParticle p = new VerletParticle(vertPos);
      particleList.add(p);
      planetPhysics.addParticle(p);
    }
    
    // turn mesh edges into springs
    int inc = 0;
    for (WingedEdge e : mesh.edges.values()) {
      if(inc % 12 == 0 ) { // only every 12th edge into a spring, otherwise suuuuuper slow if every edge becomes a spring.
        VerletParticle a = planetPhysics.particles.get(((WEVertex) e.a).id);
        VerletParticle b = planetPhysics.particles.get(((WEVertex) e.b).id);
        planetPhysics.addSpring(new VerletSpring(a, b, a.distanceTo(b), 1f));
      }
      inc++;
    }    
    hashId = planetPhysicsMapCounter;
    planetPhysicsMap.put((Integer)hashId, planetPhysics);
    planetPhysicsMapCounter++;
    
  }
  
  
  GLTexture createTexture(String filename) {
    return new GLTexture(ProcessingCanvas, filename);
  }  
  
  
  
  
  void jitter(int planetNumber) {
    float mappedF = map(planetNumber > freqs.length-1 ? freqs[round(random(0,freqs.length-1))] : freqs[planetNumber], 0, 1, 0, jitter);
    /*-----
    Number of ideas to improve this:
     Use SimplexNoise to make a levelled-out randomisation, akin to an actual planet surface
    -----*/  
    // take the places of the vertex's and place into particle positions??
    //for (int i = 0; i < verts.length/4; i++) {}

    float jiggleFactor = 4.1;//float jiggleFactor = 0.7 / constrain(peak,1,4); // the idea is to constrain the jiggle the more general background noise in the room there is. See OSC tab for peak.
    // take the particle postions and update the place of the vertex in the model, adding a jitter effect via mappedF.
    
    for(int i = 0; i < vec3DList.size(); i++) {
        Vec3D vertexVec3D = particleList.get(i);

        // now, update the particles to the placement of vertexes
        if(altPlanetType == 1) {
          vertexVec3D.x = verts[4*i];
          vertexVec3D.y = verts[4*i+1];
          vertexVec3D.z = verts[4*i+2];
        }
        
        float r = random(1);
        // update the vertexes to placement of particles
        if(pixelGrid[i] == 1) {// aka, if the ruleset dictates that this vertex can move, then:
          jiggleFactor = 3; /////////////////////////////////////////////////////////////////////////////////////////////////////////////
          verts[4*i] = vertexVec3D.x + mappedF*random(-jiggleFactor,jiggleFactor) + mappedF*0.01; // + mappedF*0.01 moves the planet in a funny arc
          verts[4*i+1] = vertexVec3D.y + mappedF*random(-jiggleFactor,jiggleFactor) + mappedF*0.01;
          verts[4*i+2] = vertexVec3D.z + mappedF*random(-jiggleFactor,jiggleFactor) + mappedF*0.01;
        } else {
          if(r < 0.4) {
            jiggleFactor = 2; /////////////////////////////////////////////////////////////////////////////////////////////////////////////
            verts[4*i] = vertexVec3D.x + mappedF*random(-jiggleFactor,jiggleFactor) + mappedF*0.01; // + mappedF*0.01 moves the planet in a funny arc
            verts[4*i+1] = vertexVec3D.y + mappedF*random(-jiggleFactor,jiggleFactor) + mappedF*0.01;
            verts[4*i+2] = vertexVec3D.z + mappedF*random(-jiggleFactor,jiggleFactor) + mappedF*0.01;
          }
        }
    }
    model.beginUpdateVertices();
      for (int i = 0; i < verts.length/4; i++) {
        model.updateVertex(i, verts[4 * i], verts[4 * i + 1], verts[4 * i + 2]);  
    }
    model.endUpdateVertices();
  }
  
  void setPosition(PVector pos) {
    iFrame.setPosition(pos);  
  }

  boolean runOnce = false;
  int opacity = 15; //controls the opacity-in when planet is created.

  void draw(GLGraphics renderer, int planetNum) {
    pushMatrix();
    
    if(age < 255) { // fade-in effect
      model.beginUpdateColors();
        for (int i = 0; i < verts.length/4; i++) model.updateColor(i, 255, 255, 255, opacity);
      model.endUpdateColors();
      opacity++;
    }

    iFrame.translate(vel.x,vel.y,vel.z);  // moves the planet.
    iFrame.applyTransformation();
    rotate(frameCount*rOffset);
    
    jitter(planetNum);
     /*-----
     NOTE: might need this. See SwarmingSprites example.
     Disabling depth masking to properly render semitransparent
     particles without need of depth-sorting them.    
     -----*/
    renderer.setDepthMask(false);
    renderer.model(model);
    renderer.setDepthMask(true);
    popMatrix();
    
    updatePhysics();
    age++;
    
    if(age >= die) {
      destructSequence();
    }
  }
  
  void drawInteractiveFrame(GLGraphics renderer, int planetNumber) {
    scene.interactiveFrame().setPosition(getPosition()); // probably dodgy - can be fixed
    scene.interactiveFrame().applyTransformation();
  }
    
  void updatePhysics() {
    planetPhysicsMap.get(hashId).update();
  }

boolean runCrushOnce = false;
///////////// maybe physics system should only be implemented here? to save framerate?  
  void destructSequence() { 

    if(altPlanetType == 1) altPlanetType = 0; // convert to other planet type so destructs properly
       
    if(age - die == 0) {
      // briefly expand the planet
      initPlanetAttractor(-0.7,2.3);
    } else if (age - die == 24) {
      removeBehavior();
      
      // crush the planet
      initPlanetAttractor(0.95,1);  
    }
    if(age - die >= 400) {// long time to die!
      destroy();
    }
  }
  
  void destroy() {
    // get position of planet before its destroyed
    Vec3D positionOfDeath = new Vec3D(int(getPosition().x), int(getPosition().y), int(getPosition().z));
    removeBehavior();
    // remove all particles from planetPhysics
    planetPhysics.clear();
    planetPhysicsMap.remove(hashId);
    // find what index this planet is and remove it
    int indexOf = GPUPlanetList2.indexOf(this); 
    GPUPlanetList2.remove(indexOf);
    
    
    // explode particles from the death of the planet. Take a 6th of all available particles
    for(int i=0; i<int(NUM_PARTICLES/6); i++) {
      VerletParticle p = physics.particles.get(i);
      p.set(positionOfDeath);
      p.clearVelocity(); 
    }
  }
  
  /* needed for selecting planet with 3 fingers */
  void setAsInteractiveFrame(boolean is) {
    selectedGPUPlanet = this;
  }
  InteractiveFrame getFrame() {
    return iFrame;  
  }


  AttractionBehavior crushAttractor;
  Vec3D attractorPosition = new Vec3D(0,0,0); // used to update position of attractor.

  /***** PLANET ATTRACTOR METHODS *****/
  void initPlanetAttractor(float strength, float jitter) {    
    int attractorRadius = 2000; // currently arbitrary
    crushAttractor = new AttractionBehavior(attractorPosition, attractorRadius, strength, jitter);
    addBehavior();
  }
  void addBehavior() {
    planetPhysics.addBehavior(crushAttractor);  
  }
  void removeBehavior() {
    planetPhysics.removeBehavior(crushAttractor);
  }  
  PVector getPosition() {
    return iFrame.position();  
  }

}
