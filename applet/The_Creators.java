import processing.core.*; 
import processing.xml.*; 

import toxi.geom.*; 
import toxi.geom.mesh.*; 
import toxi.math.*; 
import toxi.math.noise.*; 
import toxi.processing.*; 
import toxi.physics.*; 
import toxi.physics.behaviors.*; 
import codeanticode.glgraphics.*; 
import javax.media.opengl.*; 
import remixlab.proscene.*; 
import tuioZones.*; 
import TUIO.*; 
import oscP5.*; 
import netP5.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class The_Creators extends PApplet {

/*----------------------------------------------------------------------
            PLEASE RUN IN PRESENTATION MODE (CMD+SHIFT+R)
            Note: currently an error when trying to run in Processing v2.
            Please use Processing 1.5.1

            \\\ THE CREATORS ///
            
                    BY
            
              CONSTANZA CASAS
              MARK C MITCHELL
              PIETER STEYAERT
            
/*----------------------------------------------------------------------*/


// TODO:: Could perhaps instead of each particle getting an AttractionBehaviour, it could be simulated instead by using SimplexNoise + an offset?

// TODO:: slithery snake? spring'd snake slithers past like a comet?
// TODO:: Try to work out an algorithm for having the black hole move towards groups/the center of the particles
// TODO:: constraint on particles to avoid going through planets?
// TODO:: GLOBEDETAIL in wireframeplanet: was 16, can it deal with 32? Also globeDetail in GPUPlanet2. Connected to calcSphereCoords. Was 32, now 60 ...

// DONE:: Explode the planets correctly.
// DONE:: Fix mutitouch gestures!!
// DONE:: allow for 3-finger selection of textured planets as well.
// DONE:: Learn and make the lighting better.









// This import is needed to use OpenGL directly.
 




 

final int WORLD_RADIUS = 8200; // was 9200
final float PLANET_SPEED = random(0.4f,0.7f); // speed that all planets slowly move 
final int NEW_WIREFRAME_RADIUS = round(random(60,100)); // size when new planet is created via attractor
final boolean SHOW_FRAMERATE = false;
final int NUM_INIT_WIREFRAMES = 4;
final int NUM_INIT_GPU2PLANETS = 10;
final int INTRO_TIME = 50; // was 350. // timeout before screensaver starts

OscP5 oscP5;
NetAddress myRemoteLocation;

// reference to the Processing canvas. Needed when constructing GLModels.
PApplet ProcessingCanvas;
// scene object for proscene
Scene scene;
// Helper class for drawing 3d objects to screen
ToxiclibsSupport gfx;

TuioHandler tuioHandler;

ArrayList<WireframePlanet> planetList = new ArrayList<WireframePlanet>();
ArrayList<GPUPlanet> GPUPlanetList = new ArrayList<GPUPlanet>(); // HOLDS EASTER EGG
ArrayList<GPUPlanet2> GPUPlanetList2 = new ArrayList<GPUPlanet2>();

WireframePlanet planet;
WireframePlanet selectedPlanet; // planet that is currently the scene's interactive frame.
GPUPlanet2 selectedGPUPlanet;

WorldSphere worldSphere;
StarSphere starSphere;
DefaultSceneView defaultSceneView; // class holding a single scene as default camera view. See TuioZones tab.

float jitter = 50; // very important! jitter intensity of planets to frequencies.

GLGraphics renderer;

float lightSpecular[] = {0,222,222,1}; // specular adds a 'shiny' spot to your models // FOR LIGHTING.


HashMap<Integer, VerletPhysics> planetPhysicsMap; // holds the physics necessary for GPUPlanet2's

public void setup() {
  size(screen.width, screen.height, GLConstants.GLGRAPHICS);
  
  ProcessingCanvas = this; // reference to PApplet
  g3 = (PGraphics3D)g; // needed for gui() perspective thingo, so controlP5 works correctly

  gfx = new ToxiclibsSupport(this);

  scene = new Scene(this);
  scene.setRadius(WORLD_RADIUS);
  scene.setAxisIsDrawn(false); scene.setGridIsDrawn(false); scene.enableMouseHandling(false);
  scene.setInteractiveFrame(new InteractiveFrame(scene));  

  /***** TUIO *****/
  zones = new TUIOzoneCollection(this);
  tuioHandler = new TuioHandler();  
  /***** OSC *****/
  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("127.0.0.1", 12000); 
  /***** PHYSICS ******/
////////////////
  planetPhysicsMap = new HashMap<Integer,VerletPhysics>();
  
  physics = new VerletPhysics();
  physics.setDrag(PARTICLE_DRAG);

  /***** LOAD TEXTURES *****/
  loadTextures();  

  /***** OBJECTS *****/
  sphereDetail(8); // for planets
  vortexSetup();

  /* blackhole setup */
  blackHoleSetup();
  /* particle setup */
  addParticles(NUM_PARTICLES);
  /* attractor setup */
  a = new Attractor();   

  for (int i=0; i<NUM_INIT_WIREFRAMES; i++) 
    planet = new WireframePlanet();
    


    
  /* create world sphere */
  worldSphere = new WorldSphere();
  /* create star sphere */
  starSphere = new StarSphere();
  /* calc sphere coords one last time to control textured planet tex-coords */
  calcSphereCoords(60, WORLD_RADIUS);
  
  
  

  
  
///////////////////
///////////
//////// TESTING ONLY CREATE RANDOM NEW TEXTURED PLANETS
GPUPlanet2 gpuPlanet2;
for (int i=0; i<NUM_INIT_GPU2PLANETS; i++) {
    WETriangleMesh mesh = new WETriangleMesh();
    mesh.addMesh(new Sphere(100).toMesh(16));
    PVector p = new PVector(random(-1300,1300),random(-1300,1000),random(-1300,1300));
    PVector vel = new PVector(random(3),random(3),random(3));  
    gpuPlanet2 = new GPUPlanet2(mesh,p,vel);
  }
/////////////
  
  
  // setup default camera position for double-tab gesture.
  defaultSceneView = new DefaultSceneView();

  noFill();  

  scene.camera().interpolateTo(defaultSceneView.getFrame()); // interpolate to default view to begin
}



public void draw() {
  if(frameCount < 422)     background(0);

  
  renderer = (GLGraphics) g;
  if(SHOW_FRAMERATE) if(frameCount % 100 == 0) println(frameRate);
  checkIntro();
  if (intro == false || introCounterCounter <=1) {
    background(0); // THIS IS CURRENTLY BROKEN. FIX IT!!
  }    
  tuioUpdate();  // runs entire tuio operation

//bang(); // AudioPeak note dont run this except for testing!!

  /***** draw blackholes *****/
  blackHoleIn.draw();
  blackHoleOut.draw();

  /***** draw particles *****/
  drawParticles();

  pushMatrix();
  /***** draw vortexes *****/
  for(int i = 0; i < vortexesQueue.size(); i++)
    vortexesQueue.get(i).draw(true); // show vortexes = true.


/////////////////  // every once in a while, create a new vortex
  if (frameCount % 60 == 0) {
    if (PApplet.parseInt(random(100)) <= 20) {
      vortexesQueue.offer(new Vortex());
    } 
  } 


  drawPlanetIfSelected();
  
  /***** draw wireframe planets *****/  
  for (int i = 0; i < planetList.size(); i++) {
    if (intro == false) {
      planetList.get(i).draw(i);
    }
  }
  
  // every once in a while, create a new random planet
  if(frameCount % 2000 == 0) {
    PVector randPos = new PVector(random(-1300,1300),random(-1300,1000),random(-1300,1300));
    WireframePlanet p = new WireframePlanet(randPos,15);  
  }
    
  popMatrix();

  //draw attractor sphere
  if(attractorEnabled) a.draw(); 

  // Switches to pure OpenGL mode
  renderer.beginGL();
  /***** render lighting, but only if intro is not happening *****/
  if(!intro) glLightingGo(renderer);
  
  /***** draw world sphere *****/
  if (intro == false) {
    worldSphere.draw(renderer);
    starSphere.draw(renderer);
  }

 /* if(easterEgg) {
    for (int i = 0; i < planetList.size(); i++)
      planetList.get(i).createEasterEgg();
    easterEgg = false;
  }*/
  
  pushMatrix();
  
  // CONTROL EASTER EGG DRAWING
 /* if(GPUPlanetList.size() > 0) {
    for (int i = 0; i < GPUPlanetList.size(); i++) {
      if (intro == false) {
      GPUPlanetList.get(i).draw(renderer, i);  
      }
    }
  }*/
  
  /***** draw textured planets *****/  
  for (int i = 0; i < GPUPlanetList2.size(); i++) {
    if (intro == false)
      GPUPlanetList2.get(i).draw(renderer, i);  
  } 
  drawPlanetIfSelected2(renderer);
  
  popMatrix();
  
  // Back to processing
  renderer.endGL();    


  gui();
  
  ////****** REVIEW THISSSSSS */
  //noiseIncrementer();
/*--- CLOSE OF DRAW FUNCTION HERE ---*/
}

///////////////////////
////// ***** REVIEW THIS
///////////
float NS = 0.05f; // noise scale (try from 0.005 to 0.5)
float noiseVal = 0;
int noiseInc = 0;

public void noiseIncrementer() {
  noiseVal = (float) SimplexNoise.noise(NS*noiseInc, 0); 
  noiseInc = noiseInc % 100 == 0 ? 1 : ++noiseInc;
}

public void drawPlanetIfSelected() {
 if(selectedPlanet != null) {
   // temporarily remove selected planet from planet list so doesn't get double-drawn.
   planetList.remove(selectedPlanet);
   
   if(scene.interactiveFrameIsDrawn()) {
     if(selectedPlanet != null)
       selectedPlanet.drawInteractiveFrame(round(random(0,freqs.length-1)));
   } else {
     // re-add the selected planet into planetList to draw normally.
     planetList.add(selectedPlanet);
     selectedPlanet = null;
   }		
  }
}


public void drawPlanetIfSelected2(GLGraphics renderer) {
 if(selectedGPUPlanet != null) {
   if(scene.interactiveFrameIsDrawn()) {
     selectedGPUPlanet.drawInteractiveFrame(renderer, round(random(0,freqs.length-1)));
   } else {
     selectedGPUPlanet = null;
   }		
  }
}




/* old, here to revert to if necessary */
public void glLightingGo(GLGraphics renderer) {
  // will cast the black shaddow on side of spheres.
  renderer.gl.glEnable(GL.GL_LIGHTING);

  // Disabling color tracking, so the lighting is determined using the colors
  // set only with glMaterialfv()
  //renderer.gl.glDisable(GL.GL_COLOR_MATERIAL);

  // for all this gl stuff see Toxiclibs example in GLGraphics > Integration
  // Enabling color tracking for the specular component, this means that the 
  // specular component to calculate lighting will obtained from the colors 
  // of the model (in this case, pure green).
  // This tutorial is quite good to clarify issues regarding lighting in OpenGL:
  // http://www.sjbaker.org/steve/omniv/opengl_lighting.html
  renderer.gl.glEnable(GL.GL_COLOR_MATERIAL);
  renderer.gl.glColorMaterial(GL.GL_FRONT_AND_BACK, GL.GL_SPECULAR);

  renderer.gl.glEnable(GL.GL_LIGHT0);
  // the next two floats are rgb colours ({r,g,b,a}, 0?)
  // AMBIENT sets the colour on the non-litup side
  //renderer.gl.glMaterialfv(GL.GL_FRONT_AND_BACK, GL.GL_AMBIENT, new float[] {0.1, .1, 0.5, 1}, 0);

  // back-type colour (controls the purple/blue)
  renderer.gl.glMaterialfv(GL.GL_FRONT_AND_BACK, GL.GL_DIFFUSE, new float[] {0, 0, 1, 1}, 0);  
  
  renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_POSITION, new float[] {-1000, 600, 2000, 0 }, 0);
   
  // how does this work? This is causing the ugly drop-off razor of shadow. Want it smooth!
  // changing the first number makes some cool colour effects. Usually 1.
  //renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_SPECULAR, new float[] {211, 1, 1, 1}, 0);
}


public void glLightingGo2(GLGraphics renderer) {
  // will cast the black shaddow on side of spheres.
  renderer.gl.glEnable(GL.GL_LIGHTING);

  //renderer.gl.glDisable(GL.GL_COLOR_MATERIAL);
  renderer.gl.glEnable(GL.GL_COLOR_MATERIAL);
  renderer.gl.glColorMaterial(GL.GL_FRONT_AND_BACK, GL.GL_SPECULAR);  

  renderer.gl.glEnable(GL.GL_LIGHT0);

  // color4f is an array of floats such that {r,g,b,a}
  float lightAmbient[] = {0.2f,0,0,1}; // ambient lets a light illuminate every point in a scene
  float lightDiffuse[] = {0,0,1,1}; // diffuse lets a light illuminate objects around it

// controls fancy colours of space!
if(frameCount % 8000 == 0) {
  lightSpecular[0] = random(0,255);
  lightSpecular[1] = random(0,255);
  lightSpecular[2] = random(0,255);
  lightSpecular[3] = 1;
}

  float matAmbient[] = {1,1,1,1}; // default {1,1,1,1}
  float matDiffuse[] = {0,0,1,1}; //{0.5,0.7,0.7,1} colourful stars?
  float matSpecular[] = {1,1,1,1};
  
  float lightPosition[] = {0,0,2000,0}; // the 0 on the end here makes all the difference! if its 1 its completely different
  // http://www.oogtech.org/content/tag/gl_spot_exponent/ says 0 is to create a direction light like the sun, 1 to create a positional light like a fireball.
  
  float lightDirection[] = {0,0,-1}; // color 3f
  
  renderer.gl.glMaterialfv(GL.GL_FRONT_AND_BACK, GL.GL_AMBIENT, matAmbient, 0);
  renderer.gl.glMaterialfv(GL.GL_FRONT_AND_BACK, GL.GL_DIFFUSE, matDiffuse, 0); // controls lighting of stars. new float[]{r,g,b,a?},0);  
 // renderer.gl.glMaterialfv(GL.GL_FRONT_AND_BACK, GL.GL_SPECULAR, matSpecular, 0); 
  
//  renderer.gl.glMaterialf(GL.GL_FRONT_AND_BACK, GL.GL_SHININESS, 20f); 

 // if(frameCount >= 200) renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_AMBIENT, new float[]{0.1,0.1,0.1,1}, 0); // controls making other side not so pitch-dark.
  
  renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_DIFFUSE, lightDiffuse, 0);  
  renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_SPECULAR, lightSpecular, 0);   

  renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_POSITION, lightPosition, 0);
  renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_SPOT_DIRECTION, lightDirection, 0);
  renderer.gl.glLightf(GL.GL_LIGHT0, GL.GL_SPOT_CUTOFF, 180f);
  renderer.gl.glLightf(GL.GL_LIGHT0, GL.GL_SPOT_EXPONENT, 128); // exponent is 0-128. high exponent values make the light stronger in the middle of the light cone
 
}
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
   
  public void addBehavior() {
    physics.addBehavior(attractionBehavior);
    tempAttractorRadius = attractorRadius; // tempAttractorRadius is a global. For allowing the attractor to expand/shrink when being used.
  }  
  
  public void removeBehavior() {
    physics.removeBehavior(attractionBehavior);  
  } 
  
  public PVector getPosition() {
    return iFrame.position();
  }
  public void setPosition(PVector pos) {
    iFrame.setPosition(pos);
  }
  
  private void updateAttractorPosition() {
    PVector pvec = getPosition();
    attractorPosition.set(pvec.x, pvec.y, pvec.z);
  }
  public void updateAttractorRadius(float r) {
    attractionBehavior.setRadius(r);
  }

  
  public void draw() {
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
  
  public void moveAttractor(int tcurX, int tcurY) {
    // convert cursor position to world coords, and then set the interactive frame to this world position.
    scene.interactiveFrame().setPosition(convertScreenToWorld(new PVector(tcurX,tcurY,0)));
    // now that interactiveFrame is correct, update position of iFrame to the same.
    iFrame.setPosition(scene.interactiveFrame().position());
  }  

  /* draw the attractor & activate behaviour if scruch gesture has been performed. See TuioZones tab */
  public void toggleDrawInteractiveFrame(int tcurX, int tcurY) {
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


BlackHole blackHoleOut;
BlackHole blackHoleIn;

public void blackHoleSetup() {
  blackHoleIn = new BlackHole();
  blackHoleOut = new BlackHole(200, -1f);
}

class BlackHole {
  float sketchSize = WORLD_RADIUS/10;  // or 10? 
  InteractiveFrame iFrame;
  PVector vel = new PVector(0,0,0);
  PVector acc = new PVector(-0.0001f, 0.01f, 0.0000001f);
  Vec3D position = new Vec3D(0,0,0); // used to update position of attractor. use position.set().
  int attractorRadius = 900;
  float strength = 5.5f;
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
  
  public void initInteractiveFrame() {
    iFrame = new InteractiveFrame(scene);
    iFrame.setPosition(randomPVector()); // sets random position of black hole.
  }  

  public void draw() {
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
      scale(constrain(peak,0,1.7f));
      gfx.mesh(whiteBlackHole, true, 40);        
    }
    popStyle();
    popMatrix();
    updatePosition();
  } 
  
  
  public void updatePosition() {
    acc.set(random(-1, 1), random(-1, 1), random(-1, 1));
    acc.normalize();
    acc.mult(random(0.1f)); 
    vel.add(acc);
    vel.limit(topSpeed);
    addToPosition(vel);
    
    //position.set(getPositionAsVec3D()); // update position for attractor behaviour
    PVector pv = iFrame.position();
    position.set(pv.x, pv.y, pv.z);
  }
  public void addToPosition(PVector posAddition) {
    PVector newPosition = getPosition();
    newPosition.add(posAddition);
    iFrame.setPosition(newPosition);
  }
  
  public void setPosition(PVector pos) {
    iFrame.setPosition(pos); 
  }  
  public void addBehavior() {
    physics.addBehavior(blackholeAttractor);  
  }  
  public void removeBehavior() {
    physics.removeBehavior(blackholeAttractor);  
  }  
  
  public PVector randomPVector() {
    return new PVector(random(-sketchSize, sketchSize), random(-sketchSize, sketchSize), random(-sketchSize, sketchSize));
  }
  
  public PVector getPosition() {
    return iFrame.position();
  }
  /* needed for VerletPhysics */
  public Vec3D getPositionAsVec3D() {
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
/***** ROUND PLANET FULL TEXTURE *****/
/***** NOT USED ******/
class GPUPlanet {
  
  private InteractiveFrame iFrame;
  private WETriangleMesh mesh;
  // model used to store mesh on GPU and render
  private GLModel model;
  private int globeDetail = 32; // dynamically create this?
  private int initWidth = 1400;
  
  GPUPlanet(WETriangleMesh _mesh, PVector position) {
    initInteractiveFrame(position);
    mesh = _mesh;
    createPlanet(mesh);
    GPUPlanetList.add(this); // add to planet list.
  }
  
  public void initInteractiveFrame(PVector position) {
    iFrame = new InteractiveFrame(scene);
    // sets the threshold for how easy it is to select a planet. Independant of how close/far the planet is to camera.
    // I wonder if this could be set as a function of how far away the planet is to the camera?
    iFrame.setGrabsMouseThreshold(30);
    iFrame.setPosition(position);
  }  

  public void createPlanet(WETriangleMesh mesh) {
    /*-----
     GLGraphics is probably best to be used for texture manipulation, which can
     then be placed onto the model in the gpu in realtime and manipulated.
    -----*/
    mesh.rebuildIndex();
   
    // get flattened vertex array (for processing in GL)
    float[] verts=mesh.getMeshAsVertexArray();
    // in the array each vertex has 4 entries (XYZ + 1 spacing(W))
    int numOfVertices=verts.length/4;  
    // get flattened norms array (for processing in GL)

    float[] norms=mesh.getVertexNormalsAsArray();
    calcSphereCoords(globeDetail, initWidth);
    /*-----
    Creates an instance of GLModel with the specified parameters:
    number of vertices, mode to draw the vertices (as points, sprites, lines, etc)
    and usage (static if the vertices will never change after the first time are initialized,
    dynamic if they will change frequently or stream if they will change at every frame).
    NOTE: I wonder if I can BLEND two together?? To get a points-to-closed-mesh effect?
    -----*/
    model = new GLModel(ProcessingCanvas, vertices.size(), TRIANGLE_STRIP, GLModel.STREAM);
    model.updateVertices(vertices);

    model.initTextures(1);       
    model.setTexture(0, loadedTextures.get(round(random(0,loadedTextures.size()-1))));
    model.updateTexCoords(0, texCoords);       

    model.initNormals();
    model.updateNormals(normals);

    // Setting model shininess.
    model.setShininess(3);
  }
  
  public GLTexture createTexture(String filename) {
    return new GLTexture(ProcessingCanvas, filename);
  }    
  
  public void jitter(int planetNumber) {
    float mappedF = map(planetNumber > freqs.length-1 ? freqs[PApplet.parseInt(random(0,freqs.length-1))] : freqs[planetNumber], 0, 1, 0, jitter);
    
    model.beginUpdateVertices();    
    for (int i = 0; i < vertices.size(); i++) {
      model.displaceVertex(i, mappedF, mappedF, mappedF);
    }
    model.endUpdateVertices();
   
  }  
  boolean runOnce = false;
  public void draw(GLGraphics renderer, int planetNum) {
    pushMatrix();
    iFrame.applyTransformation();
    
    // dodge implementation. need to fix this.
    // making the updateColor run only once when the mouse moves onto, and then off a planet.
    if (iFrame.grabsMouse()) {
      if(!runOnce) {      
        //model.beginUpdateColors();
        //for (int i = 0; i < numOfVertices; i++) model.updateColor(i, 255, 0, 0, 1);
   //     model.setColors(255,0,0);
        //model.endUpdateColors(); 
        runOnce = true;
      }
    } else if (!iFrame.grabsMouse()) {
        if(runOnce) {   
          //model.beginUpdateColors();
          //for (int i = 0; i < numOfVertices; i++) model.updateColor(i, 0, 255, 0, 225);
  //        model.setColors(255);
          //model.endUpdateColors(); 
          runOnce = false;
        }
    }
    jitter(planetNum);
    renderer.model(model);
    popMatrix();
  }
}



/*-------------------

StarSphere and WorldSphere

-------------------*/

class StarSphere {
  
  private InteractiveFrame iFrame;
  private WETriangleMesh mesh;
  private GLModel model;
  private int globeDetail = 235;
  StarSphere() {
    initMesh(WORLD_RADIUS, globeDetail);
    createPlanet(mesh);
  }  
  
  public void initMesh(int radius, int globeDetail) {
    mesh = new WETriangleMesh();
    mesh.addMesh(new Sphere(radius).toMesh(globeDetail));
  }
  
  public void createPlanet(WETriangleMesh mesh) {
    mesh.rebuildIndex();
    calcSphereCoords(globeDetail, WORLD_RADIUS*2.2f);

    model = new GLModel(ProcessingCanvas, vertices.size(), POINTS, GLModel.STATIC);
    
    // Sets the coordinates (using calcSphereCoords)
    model.updateVertices(vertices);
    model.beginUpdateVertices();
    // displace the stars to give a nice 3d effect
    int dsplace = 2800; // was 900.
    for (int i = 0; i < vertices.size(); i++) {
      model.displaceVertex(i, random(-dsplace, dsplace), random(-dsplace, dsplace), random(-dsplace, dsplace));
    }
    model.endUpdateVertices();   
     
    // Sets the normals.
    model.initNormals();
    model.updateNormals(normals);
    
    model.initColors();
    model.setColors(random(90,120)); // make background subtle.
    
    model.setShininess(3);
  }
  public void draw(GLGraphics renderer) {
    renderer.model(model);
  }
}


class WorldSphere {
  
  private InteractiveFrame iFrame;
  private WETriangleMesh mesh;
  private GLModel model;
  private int globeDetail = 135;
  
  WorldSphere() {
    initMesh(WORLD_RADIUS, globeDetail);
    createPlanet(mesh);
  }
  
  public void initMesh(int radius, int globeDetail) {
    mesh = new WETriangleMesh();
    mesh.addMesh(new Sphere(radius).toMesh(globeDetail));
  }

  public void createPlanet(WETriangleMesh mesh) {
    mesh.rebuildIndex();  
    //calcSphereCoords(globeDetail, WORLD_RADIUS*1.95);
    calcSphereCoords(globeDetail, WORLD_RADIUS*3.8f);
    
    model = new GLModel(ProcessingCanvas, vertices.size(), TRIANGLE_STRIP, GLModel.STATIC);
    
    // Sets the coordinates. (using calcSphereCoords)
    model.updateVertices(vertices);
    // deliberately fucks up the background
    /*model.beginUpdateVertices();
    for (int i = 0; i < vertices.size(); i++) {
      model.displaceVertex(i, random(-240, 240), random(-240, 240), random(-240, 240));
    }
    model.endUpdateVertices();
    */
    model.initTextures(1);
    model.setTexture(0, new GLTexture(ProcessingCanvas, WORLD_BACKGROUND));
    model.updateTexCoords(0, texCoords);       
    // Sets the normals.
    model.initNormals();
    model.updateNormals(normals);
    model.initColors();
    model.setColors(120); // make background subtle.
  }
  
  public void draw(GLGraphics renderer) {
    renderer.model(model);
  }
}
/***** THIS PLANET CREATES THE PLANET EXACTLY LIKE THE SHAPE OF THE MESH *****/
int planetPhysicsMapCounter = 0; // needed to keep track of hashmaps of planets!

class GPUPlanet2 {  
  private InteractiveFrame iFrame;
  private WETriangleMesh mesh;
  private GLModel model;
  private int globeDetail = 32; // dynamically create this? 32 or 60? has a BIG important impact. Final detail of texturedglobe!
  private int initWidth = 10; 
  private int age = 0; // age
/////////////  
  private int die = round(random(900,1500)); // was 1500.
  private PVector vel; // controls planet movement
  private float rOffset = random(0.0001f, 0.015f); // rotation offset
  float[] verts; // flattened array of vertices from toxiclibs mesh
  int hashId; 
  VerletPhysics planetPhysics;
  
  GPUPlanet2(WETriangleMesh _mesh, PVector position, PVector _vel) {
    initInteractiveFrame(position);
    mesh = _mesh;
    createPlanet(mesh);
    vel = _vel;
    GPUPlanetList2.add(this); // add to planet list.
  }
  
  public void initInteractiveFrame(PVector position) {
    iFrame = new InteractiveFrame(scene);
    iFrame.setGrabsMouseThreshold(30);
    iFrame.setPosition(position);
  }  

  public void createPlanet(WETriangleMesh mesh) {
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

  public void initPhysics(WETriangleMesh mesh) {
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
      if(inc % 16 == 0 ) {
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
  
  
  public GLTexture createTexture(String filename) {
    return new GLTexture(ProcessingCanvas, filename);
  }  
  
  public void jitter(int planetNumber) {
    float mappedF = map(planetNumber > freqs.length-1 ? freqs[round(random(0,freqs.length-1))] : freqs[planetNumber], 0, 1, 0, jitter);
    /*-----
    Number of ideas to improve this:
     Use SimplexNoise to make a levelled-out randomisation, akin to an actual planet surface
    -----*/  
    // take the places of the vertex's and place into particle positions??
    for (int i = 0; i < verts.length/4; i++) {

    }

    float jiggleFactor = 6.1f;//float jiggleFactor = 0.7 / constrain(peak,1,4); // the idea is to constrain the jiggle the more general background noise in the room there is. See OSC tab for peak.
    // take the particle postions and update the place of the vertex in the model, adding a jitter effect via mappedF.
    for(int i = 0; i < vec3DList.size(); i++) {
        Vec3D vertexVec3D = particleList.get(i);

        // now, update the particles to the placement of vertexes
        vertexVec3D.x = verts[4*i];
        vertexVec3D.y = verts[4*i+1];
        vertexVec3D.z = verts[4*i+2];


        // update the vertexes to placement of particles
        verts[4*i] = vertexVec3D.x + mappedF*random(-jiggleFactor,jiggleFactor) + mappedF*0.01f; // + mappedF*0.01 moves the planet in a funny arc
        verts[4*i+1] = vertexVec3D.y + mappedF*random(-jiggleFactor,jiggleFactor) + mappedF*0.01f;
        verts[4*i+2] = vertexVec3D.z + mappedF*random(-jiggleFactor,jiggleFactor) + mappedF*0.01f;
    

    }
    model.beginUpdateVertices();
      for (int i = 0; i < verts.length/4; i++) {
        model.updateVertex(i, verts[4 * i], verts[4 * i + 1], verts[4 * i + 2]);  
    }
    model.endUpdateVertices();
  }
  
  public void setPosition(PVector pos) {
    iFrame.setPosition(pos);  
  }

  boolean runOnce = false;
  int opacity = 15; //controls the opacity-in when planet is created.

  public void draw(GLGraphics renderer, int planetNum) {
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
  
  public void drawInteractiveFrame(GLGraphics renderer, int planetNumber) {
    scene.interactiveFrame().setPosition(getPosition()); // probably dodgy - can be fixed
    scene.interactiveFrame().applyTransformation();
  }
    
  public void updatePhysics() {
    planetPhysicsMap.get(hashId).update();
  }

boolean runCrushOnce = false;
///////////// maybe physics system should only be implemented here? to save framerate?  
  public void destructSequence() { 
//      model.beginUpdateColors();
//        for (int i = 0; i < verts.length/4; i++) model.updateColor(i, opacity, opacity, opacity, opacity);
//      model.endUpdateColors();
//      opacity -= 3;
    
    if(age - die == 0) {
      // briefly expand the planet
      initPlanetAttractor(-0.7f,2.3f);
    } else if (age - die == 24) {
      removeBehavior();
      // crush the planet
      initPlanetAttractor(0.95f,1);  
    }
    if(age - die >= 180)
      destroy();
  }
  
  public void destroy() {
    removeBehavior();
    // remove all particles from planetPhysics
    planetPhysics.clear();
    planetPhysicsMap.remove(hashId);
    // find what index this planet is and remove it
    int indexOf = GPUPlanetList2.indexOf(this); 
    GPUPlanetList2.remove(indexOf);
  }

  /* needed for selecting planet with 3 fingers */
  public void setAsInteractiveFrame(boolean is) {
    selectedGPUPlanet = this;
  }
  public InteractiveFrame getFrame() {
    return iFrame;  
  }


  AttractionBehavior crushAttractor;
  Vec3D attractorPosition = new Vec3D(0,0,0); // used to update position of attractor.

  /***** PLANET ATTRACTOR METHODS *****/
  public void initPlanetAttractor(float strength, float jitter) {    
    int attractorRadius = 2000; // currently arbitrary
    crushAttractor = new AttractionBehavior(attractorPosition, attractorRadius, strength, jitter);
    addBehavior();
  }
  public void addBehavior() {
    planetPhysics.addBehavior(crushAttractor);  
  }
  public void removeBehavior() {
    planetPhysics.removeBehavior(crushAttractor);
  }  
  public PVector getPosition() {
    return iFrame.position();  
  }

}
boolean audioBang = false;
boolean printO = false;
float peak;
float scaleAudio = 10;

float[] freqs = new float[7];

public void oscEvent(OscMessage theOscMessage) {
  /* check if theOscMessage has the address pattern we are looking for. */
 if (theOscMessage.checkAddrPattern("audioBang") == true) {
    if(theOscMessage.checkTypetag("f")) {
      if (theOscMessage.get(0).floatValue() == 1.0f) {
        audioBang = true;
      }  
    }
 } 
  if(theOscMessage.checkAddrPattern("array") == true) {
     for (int i = 0; i <= 6; i++) {
       freqs[i] = theOscMessage.get(i).floatValue();
     }
  } 
 
 /*   if (printO == true) {   
    println("### received an osc message. with address pattern "+theOscMessage.addrPattern() +
    " || " + theOscMessage.addrPattern() +" = " + theOscMessage.get(0).floatValue() );
  }
  */

  if(theOscMessage.checkAddrPattern("peak") == true) {
    peak = theOscMessage.get(0).floatValue()*scaleAudio*(scaleAudio/9);
  }  
}

/* function to run if theres a new peak value in audio */
public void bang() {
 if (audioBang == true) {
    background(9);
    audioBang = false;
    //planet = new WireframePlanet();
    //smoothAllMeshes();
  }
}


public void smoothAllMeshes() {
  for(WireframePlanet p : planetList)
    p.smoothToxicLibsMesh();
}
/* ----------------------------------------         =) (random smiley)
        S E T T I N G S     P A R T I C L E S
-----------------------------------------------------------*/

final int NUM_PARTICLES = 770;
float PARTICLE_WIDTH = 5;
float PARTICLE_DRAG = 0.06f;
int randomStart = 400; // random starting position for particles between - & + all directions of this number.

int introCounter = INTRO_TIME;
int introCounterCounter = 0;

VerletPhysics physics;

AttractionBehavior mouseAttractor;

boolean mouseHandling = true;

Attractor a; // at the moment only one attractor at a time.

boolean intro = false;


/*****
  PARTICLE GLOBAL FUNCTIONS
*****/
int moderator = 0;

public void addParticles(int NUM_PARTICLES) {
  for(int i=0; i < NUM_PARTICLES; i++) {
    float weight = random(2,4);
    VerletParticle p = new VerletParticle(random(-randomStart,randomStart), random(-randomStart,randomStart), random(-randomStart,randomStart), weight);   
    physics.addParticle(p);
    // add a negative attraction force field around the new particle
    //if(moderator % 14 == 0)
      physics.addBehavior(new AttractionBehavior(p, PARTICLE_WIDTH*4, -3.2f, .2f));
    moderator++;
  }
}

public void drawParticles() {
  pushStyle();
  fill(255);
  //noStroke();
  stroke(255);
  PVector blackHoleInPos = blackHoleIn.getPosition();  
  physics.update();
  
  for (VerletParticle p : physics.particles) {    
    // check if particle is in the center of a black hole or out of world radius range
    if(dist(blackHoleInPos.x, blackHoleInPos.y, blackHoleInPos.z, p.x, p.y, p.z) <= 75 || abs(p.x) >= WORLD_RADIUS/3.1f || abs(p.y) >= WORLD_RADIUS/3.1f || abs(p.z) >= WORLD_RADIUS/3.1f) { 
       p.set(blackHoleOut.getPositionAsVec3D());
       p.clearVelocity();
    }
    pushMatrix();
    translate(p.x, p.y, p.z);
    noStroke();
    box(p.getWeight()*2);
    //point(p.x,p.y,p.z);
    popMatrix();
  }
  popStyle();
  
}


public void removeParticle() {
  physics.particles.remove(physics.particles.size()-1);
}


public void checkIntro() {
  if (tuioCursorList.length != 0) {
  //  intro = false;
    introCounter = INTRO_TIME;
    introCounterCounter = 0;
  }
  introCounter--;
  if (introCounter <= 0) {
    introCounterCounter++;
    introCounter = 0;
    intro = true;
  }
}

public void trail() {
  if (intro == true) {
    pushStyle();
    if (frameCount % 10 == 0) {
      fill(0, 10);
      rect(0, 0, width, height);
    }
    popStyle();
  }
} 
/*----------------------------------------------------------------------
            GESTURES
            
            rotation = degrees(map(rotate_, 0, width, 0, 10)) (total)
            pinching = lineX                                   (total)
            
            pinching temp = scalef
            rotating temp = rotatef
/*----------------------------------------------------------------------*/

int tcurX = 0;
int tcurY = 0;
int tcurXforZ = 0;
int tcurYforZ = 0;
PVector t1;
PVector t2;
//PVector tcur;

float totaal, average;
float easing = 0.1f;

float scrunch5;
float scrunch5_init; 
float scrunch5_dis;
boolean scrunch5EntryPoint = false; 

//PVector to        = new PVector();
//PVector pto       = new PVector();
//PVector from      = new PVector();
//PVector pfrom     = new PVector();
//boolean sampling, gesture, rotating, pinching = false;
//float gestureCounter;
float tzScaleFactor, tzRotateFactor;

float lineX = 0;
float rotate_ = 0;

public void gesturesChecker() {
  tzScaleFactor = zones.getGestureScale("canvas");
  text(tzScaleFactor, 10, 30);
  tzRotateFactor = zones.getGestureRotation("canvas");
  text(tzRotateFactor, 10, 50);  
  /*
  float offset = 5;
  int[][] coord = zones.getPoints();
    
  if(dist(from.x, from.y, pfrom.x, pfrom.y) <= offset && dist(to.x, to.y, pto.x, pto.y) <= offset) {
    gesture = false;
  }
  
  if(dist(from.x, from.y, pfrom.x, pfrom.y) <= offset || dist(to.x, to.y, pto.x, pto.y) <= offset) {
    if (gesture == true && gestureCounter >= 10 && pinching == false) {
      rotating = true;
    }
  } else {
    if (gesture == true && gestureCounter >= 10 && rotating == false) {
      pinching = true;
    }
  }
//  println("gesture is " + gesture + " || rotating is " + rotating + " || pinching is " + pinching);
/////////// NOT USED??
  if (coord.length==2) {
    if (sampling == true) {
      pfrom.set(coord[0][0], coord[0][1], 0);
      pto.set(coord[1][0], coord[1][1], 0);
    }
    gestureCounter++;
    gesture = true;  
    sampling = false;
    from.set(coord[0][0], coord[0][1], 0);
    to.set(coord[1][0], coord[1][1], 0);
  } else {
    gestureCounter = 0;
    sampling = true;
    gesture = false;
    rotating = false;
    pinching = false;
    
  }
  */
 
 /*
 if (scalef != 1 && pinching == true) {
   lineX += map(scalef, 0, 2, -1, 1);
 } 
 if (rotatef != 1 && rotating == true) {
   rotate_ += rotatef;
 }  
 if(coord.length == 2) {
   from.set(coord[0][0], coord[0][1], 0);
   to.set(coord[1][0], coord[1][1], 0);
 }
 */
 
}


/*----------------------------------------------------------------------

  DRAW TUIO STUFF

/*----------------------------------------------------------------------*/


/* pieters *//*
void drawTuioZoneCursors() {
  tuioCursorList=zones.getPoints();
  if (tuioCursorList.length>0) {
    for (int i=0;i<tuioCursorList.length;i++) {
      ellipse(tuioCursorList[i][0], tuioCursorList[i][1], 20, 20);
    }
  }
}*/

/* see gui() in controlP5 tab */
public void drawGestures() {
  pushMatrix(); 
  translate(width/2, height/2);
  rotate(degrees(map(rotate_, 0, width, 0, 10)));
  ellipse(0, 0, 20, 20);
  stroke(255, 0, 0);
  line(0-20, 0-20, 0+20, 0+20); 
  popMatrix();
}


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
  
  public void removeHandler() {
    tuioDevice.removeHandler();  
  }
  public void createAbsoluteHandler() {
    removeHandler();
    tuioDevice = new HIDevice(scene, HIDevice.Mode.ABSOLUTE);
    setSensitivity(new float[] {2f,2f,2f}, new float[] {0.0015f, 0.0015f, 0.0015f});
    addHandlerToScene();
  }
  public void createRelativeHandler() {
    removeHandler();
    tuioDevice = new HIDevice(scene, HIDevice.Mode.RELATIVE);
    setSensitivity(new float[] {-0.41f, -0.41f, 0.55f}, new float[] {0.00002f, 0.00002f, 0.000004f}); 
    addHandlerToScene();  
  }
  public void addHandlerToScene() {
    tuioDevice.addHandler(ProcessingCanvas, "tuioFeed");
    setCameraMode();
    scene.addDevice(tuioDevice); 
  }
    
  public void setSensitivity(float[] tsensitivity, float[] rotsensitivity) {
    tuioDevice.setTranslationSensitivity(tsensitivity[0], tsensitivity[1], tsensitivity[2]);
    tuioDevice.setRotationSensitivity(rotsensitivity[0], rotsensitivity[1], rotsensitivity[2]);
  }  
  public void setCameraMode() {
    tuioDevice.setCameraMode(HIDevice.CameraMode.GOOGLE_EARTH);
  }

  /***** ACCESSOR METHODS *****/
  public Vector getCursorList() {
    return tuioClient.getTuioCursors(); 
  }
  public HIDevice getTuioDevice() {
    return tuioDevice;
  }
  public TuioProcessing getTuioClient() {
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
  //zoom = map(tzScaleFactor, 0, 2, -1000, 400);
  zoom = map(tzScaleFactor, 0, 2, -2500, 400);
  if(zoom == -1050) zoom = 0; // cheap & easy way to get -2500 (faster zooming out) + having initial 0zoom at beginning). Apparently -1050 is 'the middle' of both.
  
   // if focusing on selected planet, change style of feed to rotate planet.
   if(scene.interactiveFrameIsDrawn()) {
     tuioDevice.feedTranslation(0,0,0);
     tuioDevice.feedRotation(tcurX, tcurY, zoom); 
   } else {
     tuioDevice.feedTranslation(tcurX, tcurY, zoom);
     tuioDevice.feedRotation(0,0,0);
   }
}

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
public void tuioUpdate() {
  /*----------------- D O U B L E T A P -- 
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
      if(scrunch5Counter == 25) {
        scrunchToggle = !scrunchToggle;
        //attractorActive = true;
        a.toggleDrawInteractiveFrame(tuioCursorList[0][0], tuioCursorList[0][1]); // see Attractor class.
//        runAttractor();
        scrunch5Counter = 0;
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
      if(scrunch5_dis >= 5.8f && scrunchToggle == false && runScrunchOnce == true) { // distance: between 8-9, tested on multitouch table
        scrunchToggle = true;
        runScrunchOnce = false;
        a.toggleDrawInteractiveFrame(tuioCursorList[0][0], tuioCursorList[0][1]); // see Attractor class.
      } else if(scrunch5_dis >= 6 && scrunchToggle == true && runScrunchOnce == true) {
        scrunchToggle = false;
        a.toggleDrawInteractiveFrame(tuioCursorList[0][0], tuioCursorList[0][1]);
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
public void addTuioCursor() {
  if (tuioCursorList.length == 5) {
    scrunch5EntryPoint = true;
  }

  //-------------------------------------------[START NECESSARY FOR DOUBLETAP]
     
  newPosition = new PVector(tuioCursorList[tuioCursorList.length-1][0], tuioCursorList[tuioCursorList.length-1][1]);

  if (dist(lastPosition.x, lastPosition.y, newPosition.x, newPosition.y) <= 16 && lastPosition.x != 0) {
    tripleTapCounter++; 
    if(tripleTapCounter == 2) { // 2 because of the way this method is setup. Just trust me.
      doubleTap();
      tripleTapCounter = 0;
      lastPosition = new PVector(0, 0);
      newPosition = new PVector(0, 0);
    }

  }
  
  lastPosition = new PVector(tuioCursorList[tuioCursorList.length-1][0], tuioCursorList[tuioCursorList.length-1][1]);
  

     
 //-------------------------------------------[END NECESSARY FOR DOUBLETAP]
}


/* run when doubleTap gesture is made */
public void doubleTap() {
  tuioHandler.getTuioDevice().setCameraMode(HIDevice.CameraMode.GOOGLE_EARTH);
  scene.camera().interpolateTo(defaultSceneView.getFrame(), 3);
  //scene.camera().lookAt( scene.camera().sceneCenter() );
  selectedAPlanetFlag = false;
  scene.setDrawInteractiveFrame(false);  
}


public void removeTuioCursor() {  
  
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
public int translateTuioX(float x) {
  return (int) map(x, 0, width, -width/2, width/2);
}
public int translateTuioY(float y) {
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


//-------------------[Vortex]----
//

LinkedList<Vortex> vortexesQueue;
LinkedList<AttractionBehavior> behavioursQueue;
/* note: I have a concurrent behavioursQueue to take care of adding/removing behaviours as vortexes are created/destroyed.
        You would think a simplified process would be to add/remove the one attractionBehaviour variable per Vortex instance,
        however this wasn't working as great as expected -- sometimes the behaviour wouldn't be properly removed. This way works. */
        
public void vortexSetup() {
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
  float grootteInc = .5f;  // grootte == size
  
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
    attractionBehavior = new AttractionBehavior(attractorPosition, diam*1.4f, .27f, 0); 
    addBehaviour();
  }

  public void addBehaviour() {
    behavioursQueue.offer(attractionBehavior);
    physics.addBehavior(attractionBehavior);
  } 
  public void removeBehaviour() {
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
      strokeWeight(0.5f);
      if(audioBang)
        stroke(255, map(abs(noiseVal),0,1,0,25));
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
  public void die() {
    removeBehaviour(); // remove all behaviours      
    vortexesQueue.poll(); // Retrieves and removes the head (first element) of this list. (offer() adds to tail)
  }
  
  
}
  
  
 

  


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
  private float sizeTooBig = random(1.2f,1.7f); // size of a planet when it decides to become a textured planet
  int fadeIn = 210; // 0-255 color scale. controls fade-in effect when planet is created. begins at 0 when created and ++'s to 210.
  private float rOffset = random(0.0005f, 0.003f);

 
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
  public void initPlanetAttractor() {
    int attractorRadius = radius*4;
    float strength = 0.5f; // 0.15f
    float jitterAtt = 0;
    planetAttractor = new AttractionBehavior(attractorPosition, attractorRadius, strength, jitterAtt);
    planetAttractorNeg = new AttractionBehavior(attractorPosition, radius, -14, 0);
    addBehavior();
  }
  
  public void addBehavior() {
    physics.addBehavior(planetAttractor);  
    physics.addBehavior(planetAttractorNeg);
  }
  /* occasionally update the neg behaviour to match the size of the planet */
  public void updateAttNegBehavior() {
    physics.removeBehavior(planetAttractorNeg);
    planetAttractorNeg = new AttractionBehavior(attractorPosition, getRadius()*1.5f, -6, 0);
    physics.addBehavior(planetAttractorNeg);
  }
  public void explodeTheParticles() {
    physics.removeBehavior(planetAttractor);
    exploderBehavior = new AttractionBehavior(attractorPosition, getRadius(), -65, 0);
    physics.removeBehavior(exploderBehavior);
  }
  public void removeAllBehaviors() {
    physics.removeBehavior(planetAttractor);
    physics.removeBehavior(planetAttractorNeg);
  }  
  /***** END PLANET ATTRACTOR METHODS *****/
  
  
///////////////////////
///////////////
//////////////////
  public void initPhysics() {
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
  
  public void updateAttractorPosition() {
    PVector pv = iFrame.position();
    attractorPosition.set(pv.x, pv.y, pv.z);  
  }
  
  public float setScaleInc() {
    return random(0.0012f, 0.0018f);
  }
  public float setSizeTooBig() {
    return random(1.8f, 3.4f); // as a scale
  }
  
  public int addToPlanetList() {
    planetList.add(this);  // add to planetList
    return planetList.size()-1;
  }
  
  public void initMesh(int radius, int globeDetail) {
    mesh = new WETriangleMesh();
    mesh.addMesh(new Sphere(radius).toMesh(globeDetail));
    updateVerticesList();
  }
  
  public void initInteractiveFrame(PVector pos) {
    iFrame = new InteractiveFrame(scene);
    iFrame.setGrabsMouseThreshold(30);
    iFrame.setPosition(pos); // position in space
    vel = new PVector(random(-PLANET_SPEED,PLANET_SPEED),random(-PLANET_SPEED,PLANET_SPEED), random(-PLANET_SPEED,PLANET_SPEED));
  } 
  /* Convenience method */
  public void setPosition(PVector pos) {
    iFrame.setPosition(pos);
  }  
  
  /***** DRAW METHOD *****/
  public void draw(int planetNumber) {
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
      if(random(1) < 0.0f) explodeTheParticles();
      updateAttNegBehavior();
    }
    updateVerticesList(); // always appear at the end. Needed to jitter mesh

    // if too big, turn into GPUPlanet, destroy
    if(currentScale >= sizeTooBig) {
      createGPUPlanet();
      destroy();
    }
  }
  public void drawInteractiveFrame(int planetNumber) {
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
  
  public WireframePlanet createGPUPlanet() {
    GPUPlanet2 temp = new GPUPlanet2(mesh, getPosition(), vel);
    return this;
  }
  
  public WireframePlanet createEasterEgg() {
    GPUPlanet temp = new GPUPlanet(mesh, getPosition());
    return this;
  }
  
  /**** WHAT TO DO WHEN IT IS DESTROYED *****/
  public void destroy() {
    // remove all behaviours
    removeAllBehaviors();
    // find what index this planet is and remove it
    int indexOf = planetList.indexOf(this); 
    planetList.remove(indexOf);
  }
  
  public void updateVerticesList() {
    verticesList = mesh.getVertices();
  }
  
  public void jitterMesh(int planetNumber) {
    for (Vec3D v : verticesList) {
      float r = random(1);
      ////// SHOULD ALL VERTICES MOVE OR JUST SOME? PLAY WITH THIS!
      if (r < 0.4f) {
        float mappedF = map(planetNumber > freqs.length-1 ? freqs[round(random(0,freqs.length-1))] : freqs[planetNumber], 0, 1, 0, jitter);
        v.jitter(mappedF * (3.9f*r)); // play with multiplier for more/less jitter
      }
    }
  }
   
  public void scaleMesh() {
    mesh.scale(1+scaleInc);
    currentScale += scaleInc;
  }
 
  public void smoothToxicLibsMesh() {
     new LaplacianSmooth().filter(mesh, 1);
    // update lighting information
    mesh.computeVertexNormals();
  }


  public void setAsInteractiveFrame(boolean is) {
    selectedPlanet = this;
  }

  
  public void rebuildIndex() {
    mesh.rebuildIndex();
  }
  
  public void setLookingAt(boolean flag) {
    lookingAt = flag;  
  }
  
  public void removeFromPlanetList() {
    planetList.remove(this);  
  }

  /***** ACCESSOR METHODS *****/
  public WETriangleMesh getMesh() {
    return mesh;  
  }
  public InteractiveFrame getFrame() {
    return iFrame;  
  }
  public PVector getPosition() {
    return iFrame.position();  
  }
  public float getRadius() {
    return radius*currentScale;  
  }  

}

float SINCOS_PRECISION = 0.5f; 
int SINCOS_LENGTH = PApplet.parseInt(360.0f / SINCOS_PRECISION);  

ArrayList vertices;
ArrayList texCoords;
ArrayList normals;

public void calcSphereCoords(int globeDetail, float globeRadius) {
    float[] cx, cz, sphereX, sphereY, sphereZ;
    float sinLUT[];
    float cosLUT[];
    float delta, angle_step, angle;
    int vertCount, currVert;
    float r, u, v;
    int v1, v11, v2, voff;
    float iu, iv;
      
    sinLUT = new float[SINCOS_LENGTH];
    cosLUT = new float[SINCOS_LENGTH];

    for (int i = 0; i < SINCOS_LENGTH; i++) {
        sinLUT[i] = (float) Math.sin(i * DEG_TO_RAD * SINCOS_PRECISION);
        cosLUT[i] = (float) Math.cos(i * DEG_TO_RAD * SINCOS_PRECISION);
    }  
  
    delta = PApplet.parseFloat(SINCOS_LENGTH / globeDetail);
    cx = new float[globeDetail];
    cz = new float[globeDetail];

    // Calc unit circle in XZ plane
    for (int i = 0; i < globeDetail; i++)  {
        cx[i] = -cosLUT[(int) (i * delta) % SINCOS_LENGTH];
        cz[i] = sinLUT[(int) (i * delta) % SINCOS_LENGTH];
    }

    // Computing vertexlist vertexlist starts at south pole
    vertCount = globeDetail * (globeDetail - 1) + 2;
    currVert = 0;
  
    // Re-init arrays to store vertices
    sphereX = new float[vertCount];
    sphereY = new float[vertCount];
    sphereZ = new float[vertCount];
    angle_step = (SINCOS_LENGTH * 0.5f) / globeDetail;
    angle = angle_step;
  
    // Step along Y axis
    for (int i = 1; i < globeDetail; i++) {
        float curradius = sinLUT[(int) angle % SINCOS_LENGTH];
        float currY = -cosLUT[(int) angle % SINCOS_LENGTH];
        for (int j = 0; j < globeDetail; j++) {
            sphereX[currVert] = cx[j] * curradius;
            sphereY[currVert] = currY;
            sphereZ[currVert++] = cz[j] * curradius;
        }
        angle += angle_step;
    }

    vertices = new ArrayList();
    texCoords = new ArrayList();
    normals = new ArrayList();

    r = globeRadius;
    r = (r + 240 ) * 0.33f;

    iu = (float) (1.0f / (globeDetail));
    iv = (float) (1.0f / (globeDetail));
    
    // Add the southern cap    
    u = 0;
    v = iv;
    for (int i = 0; i < globeDetail; i++) {
        addVertex(0.0f, -r, 0.0f, u, 0);
        addVertex(sphereX[i] * r, sphereY[i] * r, sphereZ[i] * r, u, v);        
        u += iu;
    }
    addVertex(0.0f, -r, 0.0f, u, 0);
    addVertex(sphereX[0] * r, sphereY[0] * r, sphereZ[0] * r, u, v);
  
    // Middle rings
    voff = 0;
    for (int i = 2; i < globeDetail; i++) {
        v1 = v11 = voff;
        voff += globeDetail;
        v2 = voff;
        u = 0;    
        for (int j = 0; j < globeDetail; j++) {
            addVertex(sphereX[v1] * r, sphereY[v1] * r, sphereZ[v1++] * r, u, v);
            addVertex(sphereX[v2] * r, sphereY[v2] * r, sphereZ[v2++] * r, u, v + iv);
            u += iu;
        }
        // Close each ring
        v1 = v11;
        v2 = voff;
        addVertex(sphereX[v1] * r, sphereY[v1] * r, sphereZ[v1] * r, u, v);
        addVertex(sphereX[v2] * r, sphereY[v2] * r, sphereZ[v2] * r, u, v + iv);

        v += iv;
    }
    u=0;
  
    // Add the northern cap
    for (int i = 0; i < globeDetail; i++) {
        v2 = voff + i;
        
        addVertex(sphereX[v2] * r, sphereY[v2] * r, sphereZ[v2] * r, u, v);
        addVertex(0, r, 0, u, v + iv);
   
        u+=iu;
    }
    addVertex(sphereX[voff] * r, sphereY[voff] * r, sphereZ[voff] * r, u, v);
}

public void addVertex(float x, float y, float z, float u, float v) {
    PVector vert = new PVector(x, y, z);
    PVector texCoord = new PVector(u, v);
    PVector vertNorm = PVector.div(vert, vert.mag()); 
    vertices.add(vert);
    texCoords.add(texCoord);
    normals.add(vertNorm);
}
/***** gui specific variables *****/
PMatrix3D currCameraMatrix;
PGraphics3D g3; 

PImage gestureImage;
PImage startImage;
/*-----
Area to draw on the screen, on top of the 3d space that Proscene basically handles
http://forum.processing.org/topic/proscene-and-2d-drawing
-----*/
public void gui() {
  pushStyle();
  // Disable depth test to draw 2d on top
  hint(DISABLE_DEPTH_TEST);
  currCameraMatrix = new PMatrix3D(g3.modelview);
  // Since proscene handles the projection in a slightly different manner
  // we set the camera to Processing default values before calling camera():
  float cameraZ = ((height/2.0f) / tan(PI*60.0f/360.0f));
  perspective(PI/3.0f, scene.camera().aspectRatio(), cameraZ/10.0f, cameraZ*10.0f);
  camera();
  /*------  DRAW ON SCREEN BEGIN (put functions in here)  -----*/
  //drawGestures();     // see TUIO tab
  //drawTuioZoneCursors();
  
  //if(frameCount < 450) drawIntroImages(); // draw beginning.  
  
  if(intro)trail();  // DO NOT DELETE THIS !!!! FOR DRAWING BACKGROUND INTRO

  /*------  DRAW ON SCREEN END  -----*/
  g3.camera = currCameraMatrix;
  // Re-enble depth test
  hint(ENABLE_DEPTH_TEST);
  popStyle();
}

public void drawIntroImages() {
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





 final String WORLD_BACKGROUND = "textures/background4.png";
 ArrayList<GLTexture> loadedTextures;


 /**
  * preload all textures into loadedTextures.
  */
public void loadTextures() {
  loadedTextures = new ArrayList<GLTexture>();
  gestureImage = loadImage("gestures.png"); // gesture intro image
  startImage = loadImage("thecreators.png"); // intro image
  
  String texturePath = sketchPath + "/data/textures/";
  File[] fileList = listFiles(texturePath);
  String[] textureNames = new String[fileList.length];

  //println("# of images in folder: " + fileList.length);

  for (int i = 0; i < fileList.length; i++) {
    File fileAtIndex = fileList[i];
   
    // load texture name as string
    if(!fileAtIndex.isHidden()) { // parse out .ds_store etc
      textureNames[i] = texturePath+fileAtIndex.getName();
    }
    //println("Name of texture: " + fileAtIndex.getName());
  }
  
/***** FIX THIS!!! ONLY ONE TEXTURE JUST SO IT LOADS FASTER.
********
*******
*/
//  loadedTextures.add(new GLTexture(ProcessingCanvas, textureNames[0]));
/*** UNCOMMENT THIS FOR PRODUCTION!! ***/
  for(String s : textureNames) {
    loadedTextures.add(new GLTexture(ProcessingCanvas, s));
  }
}


// This function returns all the files in a directory as an array of File objects
public File[] listFiles(String picturePath) {
  File file = new File(picturePath);
  if (file.isDirectory()) {
    File[] files = file.listFiles();
    return files;
  } else {
    // If it's not a directory
    return null;
  }
}
  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#FFFFFF", "The_Creators" });
  }
}
