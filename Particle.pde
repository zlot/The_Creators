/* ----------------------------------------         =) (random smiley)
        S E T T I N G S     P A R T I C L E S
-----------------------------------------------------------*/

final int NUM_PARTICLES = 820; //was 770 but maybe a tad too slow.
float PARTICLE_WIDTH = 5;
float PARTICLE_DRAG = 0.06f;
int randomStart = 400; // random starting position for particles between - & + all directions of this number.

int introCounter = INTRO_TIME;

VerletPhysics physics;

AttractionBehavior mouseAttractor;

boolean mouseHandling = true;

Attractor a; // at the moment only one attractor at a time.

boolean intro = false;


/*****
  PARTICLE GLOBAL FUNCTIONS
*****/
//int moderator = 0;

public void addParticles(int NUM_PARTICLES) {
  for(int i=0; i < NUM_PARTICLES; i++) {
    float weight = random(2,4);
    VerletParticle p = new VerletParticle(random(-randomStart,randomStart), random(-randomStart,randomStart), random(-randomStart,randomStart), weight);   
    physics.addParticle(p);
    // add a negative attraction force field around the new particle
    //if(moderator % 10 == 0)
      physics.addBehavior(new AttractionBehavior(p, PARTICLE_WIDTH*4, -3.2f, .2f));
    //moderator++;
  }
}

public void drawParticles() {
  pushStyle();
  fill(255);
  stroke(255);
  PVector blackHoleInPos = blackHoleIn.getPosition();  
  physics.update();
  
  for (VerletParticle p : physics.particles) {    
    // check if particle is in the center of a black hole or out of world radius range
    if(dist(blackHoleInPos.x, blackHoleInPos.y, blackHoleInPos.z, p.x, p.y, p.z) <= 75 || abs(p.x) >= WORLD_RADIUS/3.6 || abs(p.y) >= WORLD_RADIUS/3.6 || abs(p.z) >= WORLD_RADIUS/3.6) { 
       p.set(blackHoleOut.getPositionAsVec3D());
       p.clearVelocity();
    }
    pushMatrix();
    translate(p.x+(round(random(2))), p.y, p.z);
    noStroke();
    //noFill();
    //stroke(255);
    box(p.getWeight()*2);
    //point(p.x,p.y,p.z);
    popMatrix();
  }
  popStyle();
  
}

void removeParticle() {
  physics.particles.remove(physics.particles.size()-1);
}
