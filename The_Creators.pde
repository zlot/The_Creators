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

import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.math.*;
import toxi.math.noise.*;
import toxi.processing.*;
import toxi.physics.*;
import toxi.physics.behaviors.*;
import codeanticode.glgraphics.*;
// This import is needed to use OpenGL directly.
import javax.media.opengl.*; 
import remixlab.proscene.*;
import tuioZones.*;
import TUIO.*;
import oscP5.*;
import netP5.*; 


/***** INITIAL PARAMETERS *****/
final boolean PLAY_BEGINNING = false;
final int WORLD_RADIUS = 8200; // was 9200
final float PLANET_SPEED = random(0.4,0.7); // speed that all planets slowly move 
///////final int NEW_WIREFRAME_RADIUS = round(random(60,100)); // size when new planet is created via attractor
final boolean SHOW_FRAMERATE = false;
final int NUM_INIT_WIREFRAMES = 4;
final int NUM_INIT_GPU2PLANETS = 5;
final int INTRO_TIME = 1050; // was 350. // timeout before screensaver starts
float jitter = 105; // // was 50 before being inside exhibition box. //very important! jitter intensity of planets to frequencies.


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


GLGraphics renderer;

float lightSpecular[] = {0,222,222,1}; // specular adds a 'shiny' spot to your models // FOR LIGHTING.


HashMap<Integer, VerletPhysics> planetPhysicsMap; // holds the physics necessary for GPUPlanet2's

void setup() {
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



void draw() {
  renderer = (GLGraphics) g;
     
  if(SHOW_FRAMERATE) if(frameCount % 100 == 0) println(frameRate);
  
  checkIntro();
  if (intro == false || introCounterCounter <=1) {
    if (scrunch5_dis >= 100) {
      background(255, 0, 0);
    } else {
      background(0);
    }
  }  
  tuioUpdate();  // runs entire tuio operation

//bang(); // AudioPeak note:: dont run this except for testing!!

  /***** draw blackholes *****/
  blackHoleIn.draw();
  blackHoleOut.draw();

  /***** draw particles *****/
  drawParticles();

  pushMatrix();
  /***** draw vortexes *****/
  for(int i = 0; i < vortexesQueue.size(); i++)
    vortexesQueue.get(i).draw(false); // show vortexes = false.


/////////////////  // every once in a while, create a new vortex
  if (frameCount % 60 == 0) {
    if (int(random(100)) <= 20) {
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
  if(frameCount % 4500 == 0) {
    PVector randPos = new PVector(random(-1300,1300),random(-1300,1000),random(-1300,1300));
    WireframePlanet p = new WireframePlanet(randPos,newWireframeRadius());  
  }
    
  popMatrix();

  //draw attractor sphere
  if(attractorEnabled) a.draw(); 

  // Switches to pure OpenGL mode
  renderer.beginGL();
  /***** render lighting *****/
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
  
  /****** no use for noise at the moment ... */
  //noiseIncrementer();
  
/*--- CLOSE OF DRAW FUNCTION HERE ---*/
}

/*
float NS = 0.05f; // noise scale (try from 0.005 to 0.5)
float noiseVal = 0.5;
int noiseInc = 0;

void noiseIncrementer() {
  noiseVal = (float) SimplexNoise.noise(NS*noiseInc, 0); 
  noiseInc = noiseInc % 100 == 0 ? 1 : ++noiseInc;
}
*/

void drawPlanetIfSelected() {
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


void drawPlanetIfSelected2(GLGraphics renderer) {
 if(selectedGPUPlanet != null) {
   if(scene.interactiveFrameIsDrawn()) {
     selectedGPUPlanet.drawInteractiveFrame(renderer, round(random(0,freqs.length-1)));
   } else {
     selectedGPUPlanet = null;
   }		
  }
}




/* old, here to revert to if necessary */
void glLightingGo2(GLGraphics renderer) {
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


void glLightingGo(GLGraphics renderer) {
  // will cast the black shaddow on side of spheres.
  renderer.gl.glEnable(GL.GL_LIGHTING);

  //renderer.gl.glDisable(GL.GL_COLOR_MATERIAL);
  renderer.gl.glEnable(GL.GL_COLOR_MATERIAL);
  renderer.gl.glColorMaterial(GL.GL_FRONT_AND_BACK, GL.GL_SPECULAR);  

  renderer.gl.glEnable(GL.GL_LIGHT0);

  // color4f is an array of floats such that {r,g,b,a}
  float lightAmbient[] = {0.2,0,0,1}; // ambient lets a light illuminate every point in a scene
  float lightDiffuse[] = {0,0,1,1}; // diffuse lets a light illuminate objects around it

// controls fancy colours of space!
//if(frameCount % 1400 == 0) {
//  lightSpecular[0] = random(0,255);
//  lightSpecular[1] = random(0,255);
//  lightSpecular[2] = random(0,255);
//  lightSpecular[3] = 1;
//}

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

///////// note::: at web directions this was commented out!
  if(frameCount >= 200) renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_AMBIENT, new float[]{0.1,0.1,0.1,1}, 0); // controls making other side not so pitch-dark.
  
  renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_DIFFUSE, lightDiffuse, 0);  
  renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_SPECULAR, lightSpecular, 0);   

  renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_POSITION, lightPosition, 0);
  renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_SPOT_DIRECTION, lightDirection, 0);
  renderer.gl.glLightf(GL.GL_LIGHT0, GL.GL_SPOT_CUTOFF, 180f);
  renderer.gl.glLightf(GL.GL_LIGHT0, GL.GL_SPOT_EXPONENT, 128); // exponent is 0-128. high exponent values make the light stronger in the middle of the light cone
 
}


int newWireframeRadius() {
  return(round(random(60,100)));  
}
