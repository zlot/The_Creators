class CA {
  
  private int pAmount;
  private int rNumber;
  private boolean behaviorRules[];
  private boolean behaviorPossible[];
  
  /***** CONSTRUCTOR *****/
  CA(int parameterAmount, int ruleNumber) {
    pAmount = parameterAmount;
    rNumber = ruleNumber;
    
    int am = round(pow(2.0, pAmount));
    // create two arrays of size 2^parameterAmount
    behaviorRules = new boolean[am];
    behaviorPossible = new boolean[am*3];
    generateCheckRules();
  }
  
  boolean checkTheRules(boolean[] params, int ruleNumber) { // dynamic rule checking system
    // checks to see if it needs to generate new rules.
    if(ruleNumber != -1 && ruleNumber != rNumber) {
      rNumber = ruleNumber;
      generateRules();
    }
    boolean checkers[] = new boolean[pAmount]; // messy and not very functional, other solution? (breaking)
    
    int ii = round(pow(2.0, pAmount));
    for(int i=0; i<ii; i++) {
      for(int j=0; j<pAmount; j++) {
        checkers[j] = false;
      }
      
      for(int j=0; j<pAmount; j++) {
        if(params[j] == behaviorPossible[j%pAmount + pAmount*i]) {
          checkers[j] = true;
        } else {
          checkers[j] = false;
        }
      }      
      /* this checkB + for-loop seems useless? */
      boolean checkB = true;
      for(int j=0; j<pAmount; j++) {
        if(checkers[j] == true && checkB == true) {
          checkB = true;
        } else {
          checkB = false;
        }
      }
      /* END this checkB + for-loop seems useless */
      if(checkB == true) {
        return behaviorRules[i];
      }
    }
    return false; // added to please compiler, Never gets here.
  }
 
  ////////////////////////////////////
  //      PRIVATE METHODS
  ////////////////////////////////////   

  void generateRules(){ // generate a new ruleset
      if((pAmount>0) && (pAmount<10)) {
        int j = round(pow(2,(float) pAmount)-1);
        float number = pow(2, pow(2, (float) pAmount)) - rNumber-1;
          
        while(j>=0) {
          behaviorRules[(int)map(j, pow(2,(float) pAmount)-1, 0, 0, pow(2,(float) pAmount)-1)] = calc(round(number), j);
           // behaviorRules[j]=calc(round(number), j); // cool but wrong :)
          j--;
        }
      } else {println("Generate Rules: Impossible to generate rules for " + pAmount + " parameters");}    
  }

  void generateCheckRules(){ // generate all the possible rule combinations
      if ((pAmount>0) && (pAmount<10)) {
        int counter = 0;
        float number = pow(2, (float) pAmount);
        for (int i = 0; i < number; i++) {
          for (int j=pAmount - 1; j>=0; j--,counter++) {
            behaviorPossible[counter]=calc(i, j);
          }   
        }
      } else {println("Generate Check Rules: Impossible to generate rules for " + pAmount + " parameters");}
  }
    
  boolean calc(int i, int _n){ // a simple utility for generating rulesets
      int n = round(pow(2.0, _n));
      switch (abs((1+i/n) % 2)) {
        case 0: return false;
        case 1: return true;
        default: return true;
      } 
  }
}

void generateCA() {
  ////////////////////////////////////
  //      SETUP
  ////////////////////////////////////    
  final int AMOUNT_OF_PIXELS = 38*38; // to match the 1440 vertices on a planet.
  int possibleRules[] = {30,90,182,73,77,41,45,165,78,85};
  int rule = possibleRules[round(random(possibleRules.length-1))];
  rule = 30; // rule 2 shows this off, because its only a glider.
  int widthCA = int(sqrt(AMOUNT_OF_PIXELS));
  int heightCA = int(sqrt(AMOUNT_OF_PIXELS));

  int spacer = 1;
 
  int generation = -1;
  
  for(int i=0; i < AMOUNT_OF_PIXELS; i++) {
    pixelGrid[i] = 0;  
  }  
  pixelGrid[widthCA] = 1;
  
  simpleCA = new CA(3, round(random(255)));  
  
  ////////////////////////////////////
  //      UPDATE
  ////////////////////////////////////   
  
  while(generation <= heightCA-1) {
    generation++;
      for(int x=0; x<widthCA; x++) {
          PVector params = new PVector();
          if(generation == 0) {
            for(int i=0; i<AMOUNT_OF_PIXELS; i++) {
              pixelGrid[i] = 0;
            }
            int amountOfStarters = 1;
            for(int i=0; i < amountOfStarters; i++) {
              pixelGrid[widthCA/amountOfStarters*i] = round(random(1,5));
            }
          } else { // begin generations
            if(x == 0) {
              params.x = pixelGrid[(generation-1)*widthCA + x + widthCA - 1];
              params.y = pixelGrid[(generation-1)*widthCA + x];
              params.z = pixelGrid[(generation-1)*widthCA + x + 1];
            } else if(x == widthCA - 1) {
              params.x = pixelGrid[(generation-1)*widthCA + x - 1];
              params.y = pixelGrid[(generation-1)*widthCA + x];
              params.z = pixelGrid[(generation-1)*widthCA];
            } else {
              params.x = pixelGrid[(generation-1)*widthCA + x - 1];
              params.y = pixelGrid[(generation-1)*widthCA + x];
              params.z = pixelGrid[(generation-1)*widthCA + x + 1];
            }
           
          }
          boolean paramsToBool[] = new boolean[3];
          
          if (params.x == 0) {paramsToBool[0] = false;} else {paramsToBool[0] = true;}
          if (params.y == 0) {paramsToBool[1] = false;} else {paramsToBool[1] = true;}
          if (params.z == 0) {paramsToBool[2] = false;} else {paramsToBool[2] = true;}
          int i = generation*widthCA+x; if(i >= AMOUNT_OF_PIXELS) {i = AMOUNT_OF_PIXELS-1;} // make sure no array out of bounds bs.
          pixelGrid[i] = simpleCA.checkTheRules(paramsToBool, rule) == true ? 1 : 0;
          // now we have our boolean grid of rules.
      }

  }
}
