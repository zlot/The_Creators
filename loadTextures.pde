 final String WORLD_BACKGROUND = "textures/backgrounds/background4.jpg";
 ArrayList<GLTexture> loadedTextures;

/**
 * preload all textures into loadedTextures.
 */
public void loadTextures() {
  loadedTextures = new ArrayList<GLTexture>();
  gestureImage = loadImage("gestures.png"); // gesture intro image
  startImage = loadImage("thecreators.png"); // intro image
  String texturePath = sketchPath + "/data/textures/planets/";
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
  
/***** FOR TESTING PURPOSES: pre-load just one texture to speed up boot-time.
  loadedTextures.add(new GLTexture(ProcessingCanvas, textureNames[0]));
  //if this is used, comment-out the below for-loop (which pre-loads all textures)
*/
  for(String s : textureNames) {
    if(s != null) loadedTextures.add(new GLTexture(ProcessingCanvas, s));
  }
  
}


// This function returns all the files in a directory as an array of File objects
public File[] listFiles(String picturePath) {
  File file = new File(picturePath);
  if (file.isDirectory()) {
    File[] files = file.listFiles();
    return files;
  } else { // If it's not a directory
    return null;
  }
}
