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
  
  void initInteractiveFrame(PVector position) {
    iFrame = new InteractiveFrame(scene);
    // sets the threshold for how easy it is to select a planet. Independant of how close/far the planet is to camera.
    // I wonder if this could be set as a function of how far away the planet is to the camera?
    iFrame.setGrabsMouseThreshold(30);
    iFrame.setPosition(position);
  }  

  void createPlanet(WETriangleMesh mesh) {
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
  
  GLTexture createTexture(String filename) {
    return new GLTexture(ProcessingCanvas, filename);
  }    
  
  void jitter(int planetNumber) {
    float mappedF = map(planetNumber > freqs.length-1 ? freqs[int(random(0,freqs.length-1))] : freqs[planetNumber], 0, 1, 0, jitter);
    
    model.beginUpdateVertices();    
    for (int i = 0; i < vertices.size(); i++) {
      model.displaceVertex(i, mappedF, mappedF, mappedF);
    }
    model.endUpdateVertices();
   
  }  
  boolean runOnce = false;
  void draw(GLGraphics renderer, int planetNum) {
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
  
  void initMesh(int radius, int globeDetail) {
    mesh = new WETriangleMesh();
    mesh.addMesh(new Sphere(radius).toMesh(globeDetail));
  }
  
  void createPlanet(WETriangleMesh mesh) {
    mesh.rebuildIndex();
    calcSphereCoords(globeDetail, WORLD_RADIUS*2.2);

    model = new GLModel(ProcessingCanvas, vertices.size(), POINTS, GLModel.STATIC);
    
    // Sets the coordinates (using calcSphereCoords)
    model.updateVertices(vertices);
    model.beginUpdateVertices();
    // displace the stars to give a nice 3d effect
    int dsplace = 2500; // was 900.
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
  void draw(GLGraphics renderer) {
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
  
  void initMesh(int radius, int globeDetail) {
    mesh = new WETriangleMesh();
    mesh.addMesh(new Sphere(radius).toMesh(globeDetail));
  }

  void createPlanet(WETriangleMesh mesh) {
    mesh.rebuildIndex();  
    //calcSphereCoords(globeDetail, WORLD_RADIUS*1.95);
    calcSphereCoords(globeDetail, WORLD_RADIUS*3.8);
    
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
  
  void draw(GLGraphics renderer) {
    renderer.model(model);
  }
}
