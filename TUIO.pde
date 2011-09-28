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
PVector tcur;

float totaal, average;
float easing = 0.1;

float scrunch5;
float scrunch5_init; 
float scrunch5_dis;
boolean scrunch5b = false; 

//PVector to        = new PVector();
//PVector pto       = new PVector();
//PVector from      = new PVector();
//PVector pfrom     = new PVector();
//boolean sampling, gesture, rotating, pinching = false;
//float gestureCounter;
float tzScaleFactor, tzRotateFactor;

float lineX = 0;
float rotate_ = 0;

void gesturesChecker() {
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


/* pieters */
void drawTuioZoneCursors() {
  tuioCursorList=zones.getPoints();
  if (tuioCursorList.length>0) {
    for (int i=0;i<tuioCursorList.length;i++) {
      ellipse(tuioCursorList[i][0], tuioCursorList[i][1], 20, 20);
    }
  }
}

/* see gui() in controlP5 tab */
void drawGestures() {
  pushMatrix(); 
  translate(width/2, height/2);
  rotate(degrees(map(rotate_, 0, width, 0, 10)));
  ellipse(0, 0, 20, 20);
  stroke(255, 0, 0);
  line(0-20, 0-20, 0+20, 0+20); 
  popMatrix();
}


