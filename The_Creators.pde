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

// TODO:: Explode the planets correctly.
// TODO:: I WILL need new planetPhysics per textured planet! Because all planets are really at pv(0,0,0). So adding a crusher on the one system
//          actually means that ALL textured planets respond to that crusher.

// TODO:: Spring physics mesh on wireframes?
// TODO:: Could perhaps instead of each particle getting an AttractionBehaviour, it could be simulated instead by using SimplexNoise + an offset?

// TODO:: slithery snake? spring'd snake slithers past like a comet?
// TODO:: Try to work out an algorithm for having the black hole move towards groups/the center of the particles
// TODO:: Learn and make the lighting better.
// TODO:: Find something decent to replace the 2nd black hole
// TODO:: checkIntro() in draw. Clean all this up!
// TODO:: constraint on particles to avoid going through planets?
// TODO:: GLOBEDETAIL in wireframeplanet: was 16, can it deal with 32? Also globeDetail in GPUPlanet2. Connected to calcSphereCoords. Was 32, now 60 ...


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

final int WORLD_RADIUS = 9200;
WorldSphere worldSphere;
StarSphere starSphere;
DefaultSceneView defaultSceneView; // class holding a single scene as default camera view. See TuioZones tab.

float jitter = 65; // very important! jitter intensity of planets to frequencies.

GLGraphics renderer;


//////////////////
//VerletPhysics planetPhysics;
HashMap<Integer, VerletPhysics> planetPhysicsMap;
int planetPhysicsMapCounter = 0;

void setup() {
  size(screen.width, screen.height, GLConstants.GLGRAPHICS);
  
  ProcessingCanvas = this; // reference to PApplet
  g3 = (PGraphics3D)g; // needed for gui() perspective thingo, so controlP5 works correctly

  gfx = new ToxiclibsSupport(this);

  scene = new Scene(this);
  scene.setRadius(WORLD_RADIUS);
  scene.setAxisIsDrawn(false);
  scene.setGridIsDrawn(false);
  scene.enableMouseHandling(false);
  scene.setInteractiveFrame(new InteractiveFrame(scene));  

  /***** TUIO *****/
  zones=new TUIOzoneCollection(this);
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

  for (int i=0; i<7; i++) 
    planet = new WireframePlanet();

  /* create world sphere */
  worldSphere = new WorldSphere();
  /* create star sphere */
  starSphere = new StarSphere();
  /* calc sphere coords one last time to control textured planet tex-coords */
  calcSphereCoords(60, WORLD_RADIUS);
  
  // setup default camera position for double-tab gesture.
  defaultSceneView = new DefaultSceneView();

  noFill();
  renderer = (GLGraphics)g; // might need to be put in draw() ...
  

  scene.camera().interpolateTo(defaultSceneView.getFrame()); // interpolate to default view to begin
}


////////

void draw() {
///////////////////////  
//for(VerletPhysics planetPhysics : planetPhysicsMap)
  //  planetPhysics.update();
////////
  

  if(frameCount % 100 == 0) println(frameRate);
 // checkIntro();
  if (intro == false || introCounterCounter <=1) {
    if (scrunch5_dis >= 100) {
      background(255, 0, 0);
    } else {
      background(0);
    }
  }
    
  tuioUpdate();  // runs entire tuio operation

  bang(); // AudioPeak

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
//  if (frameCount % 60 == 0) {
//    if (int(random(100)) <= 20) {
//      vortexesQueue.offer(new Vortex());
//    } 
//  } 


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

  // Switches to pure OpenGL mode
  renderer.beginGL();
  /***** render lighting, but only if intro is not happening *****/
  if(!intro) glLightingGo(renderer);
  
  /***** draw world sphere *****/
  if (intro == false) {
    worldSphere.draw(renderer);
    starSphere.draw(renderer);
  }
  
  
  if(easterEgg) {
    for (int i = 0; i < planetList.size(); i++)
      planetList.get(i).createEasterEgg();
    easterEgg = false;
  }
  
  pushMatrix();
  
  // CONTROL EASTER EGG DRAWING
  if(GPUPlanetList.size() > 0) {
    for (int i = 0; i < GPUPlanetList.size(); i++) {
      if (intro == false) {
      GPUPlanetList.get(i).draw(renderer, i);  
      }
    }
  }
  
  /***** draw textured planets *****/  
  for (int i = 0; i < GPUPlanetList2.size(); i++) {
    if (intro == false)
      GPUPlanetList2.get(i).draw(renderer, i);  
  } 
  
  popMatrix();
  
  // Back to processing
  renderer.endGL();    

  //draw attractor sphere
  if(attractorEnabled) a.draw(); 
  gui();
  
  noiseIncrementer();
/*--- CLOSE OF DRAW FUNCTION HERE ---*/
}


float NS = 0.05f; // noise scale (try from 0.005 to 0.5)
float noiseVal = 0;
int noiseInc = 0;

void noiseIncrementer() {
  noiseVal = (float) SimplexNoise.noise(NS*noiseInc, 0); 
  noiseInc = noiseInc % 100 == 0 ? 1 : ++noiseInc;
}

void drawPlanetIfSelected() {
 if(selectedPlanet != null) {
   // temporarily remove selected planet from planet list so doesn't get double-drawn.
   planetList.remove(selectedPlanet);
   
////*********** REVIEW THIS
////*************
   if(scene.interactiveFrameIsDrawn()) {
     // else, planet selection mode on
     if(selectedPlanet.positionFlag()) {
       //scene.interactiveFrame().setPosition(selectedPlanet.getPosition());
       selectedPlanet.positionFlag(false);
     }
     selectedPlanet.drawInteractiveFrame(1); // the '1' here refers to the 'planet number' for frequency jitter. Should be dynamic; atm its just 1.
   }
   else {
     if(!selectedPlanet.positionFlag()) {
       selectedPlanet.setPosition(scene.interactiveFrame().position());
       selectedPlanet.positionFlag(true);
     }
     // re-add the selected planet into planetList to draw normally.
     planetList.add(selectedPlanet);
     selectedPlanet = null;
   }		
  }
}




void glLightingGo(GLGraphics renderer) {
  // will cast the black shaddow on side of spheres.
  renderer.gl.glEnable(GL.GL_LIGHTING);

  // Disabling color tracking, so the lighting is determined using the colors
  // set only with glMaterialfv()
  renderer.gl.glDisable(GL.GL_COLOR_MATERIAL);

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
  renderer.gl.glMaterialfv(GL.GL_FRONT_AND_BACK, GL.GL_AMBIENT, new float[] {0.1, .1, 0.5, 1}, 0);

  // back-type colour
  renderer.gl.glMaterialfv(GL.GL_FRONT_AND_BACK, GL.GL_DIFFUSE, new float[] {0, 0, 1, 1}, 0);  
  
  // light position float[] {x?,y?,z?, strength? (between 0 and 1?)}
 
  renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_POSITION, new float[] {
   map(tcurX, 0, width, -WORLD_RADIUS*1.5, WORLD_RADIUS*1.5),
   map(tcurY, 0, height, -WORLD_RADIUS*1.5, WORLD_RADIUS*1.5),
   map(tcurY, 0, height, WORLD_RADIUS, -WORLD_RADIUS), 0}, 0);
     
  renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_POSITION, new float[] {-1000, 600, 2000, 0 }, 0);
   
  // how does this work? This is causing the ugly drop-off razor of shadow. Want it smooth!
  // changing the first number makes some cool colour effects. Usually 1.
  renderer.gl.glLightfv(GL.GL_LIGHT0, GL.GL_SPECULAR, new float[] {211, 1, 1, 1}, 0);
}


