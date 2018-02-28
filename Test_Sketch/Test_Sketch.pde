GameScreen game;
MenuScreen menu;
int switcher = 0;

void setup() {
 ellipseMode(RADIUS);
 size(800,600);
 background(#0069b1);
 game = new GameScreen();
}

void draw() {
  switch (switcher) {
    // Display menu here
    case 0: menu = new MenuScreen(); menu.display(); break;
    
    // While the game is happening, display game screen
    case 1: if (true) game.display(); break;
    
    // Display Leaderboards here
    case 2: 
  }
}

void mousePressed() {
  if (switcher == 0 && mouseX > 100 && mouseX < 165 && mouseY > 70 && mouseY < 110) {
    switcher = 1;
  }
  if (switcher == 0 && mouseX > 100 && mouseX < 300 && mouseY > 175 && mouseY < 200) {
    switcher = 2;
  }
  if (switcher == 0 && mouseX > 100 && mouseX < 160 && mouseY > 270 && mouseY < 310) {
    exit();
  }
  // play: 100 < x < 165, 70 < y < 110
  // leaderboards: 100 < x < 300, 175 < y < 200
  // quit: 100 < x < 160, 270 < y < 310
  // println(mouseX, mouseY);
}

/********************************************************
* Class for the Game Screen
*
*
*
*********************************************************/
class GameScreen {
  int score;
  int time;
  float hazardSpeed;
 
  Player p1;
  ArrayList<Hazard> hazards;
 
  boolean paused;
 
  PFont f;
 
  // GameScreen Constuctor
  GameScreen() {
    time = millis();
    score = 0;
    hazardSpeed = 4.0;
    
    p1 = new Player(50.0, 350.0, 20.0, 0);
    hazards = new ArrayList<Hazard>();
    
    paused = false;
    
    f = createFont("Arial", 26, true);
    textFont(f, 24);
  }
 
  /*****************************************************************
  * Checks the time since last object has been generated.
  * If delta(time) >= 1/2 second, create new hazard off screen
  * and increase the hazard speed, then reset time to current time.
  *
  * @returns true if new hazard is created
  ******************************************************************/
  boolean timeCheck() {
    int newTime = millis();
  
    if (newTime - time >= 500) {
      hazardSpeed += .1;
      hazards.add(new Hazard(850.0, random(25, 775), 30.0, 0.0));
      time = newTime;
      return true;
    }
    return false;
  }
  
  /******************************************************
  * Displays players and hazards during the game screen
  *
  * Calls GameScreen.displayHazards, Player.display, GameScreen.timeCheck
  *******************************************************/
  void display() {
    while (paused) {
      if (mousePressed)
        paused = false;
    }
    background(#0069b1);
    //println(hazards.size());
    
    text(score, 10, 25);
    
    timeCheck();

    displayHazards();
    p1.display();
  }
  
  /*******************************************
  * Displays all hazards currently Generated
  * Calls Hazard.display, GameScreen.circleIntersects
  * Uses ArrayList hazards 
  *******************************************/
  void displayHazards() {
    Hazard h;
    for (int i = 0; i < hazards.size(); i++) {
      h = hazards.get(i);
      if ( h.xpos < 0 - h.radius) {
        hazards.remove(i);
        score += 100 * (int)hazardSpeed / 4;
      } else {
        h.display(hazardSpeed);
        circleIntersects(h, p1);
      }
    }
  }
  
  /************************************************
  * Checks to see if a circular hazard and
  * the player object are intersecting
  *
  * Returns true if they are and pauses the game
  *************************************************/
  boolean circleIntersects(Hazard h1, Player p1) {
    float difX = h1.xpos - p1.xpos;
    float difY = h1.ypos - p1.ypos;
    
    float dist = sqrt(sq(difX) + sq(difY));
    
    if (dist < h1.radius + p1.radius) {
       p1.c = #ff0000;
       hazardSpeed = 0;
       paused = true;
       return true;
    }
    else return false;
  }

  /*------------------------------------------------------------*/
  // Inner Classes For Game Screen
  
  
  /*******************************************
  * Player Class
  * Holds all variables of a player object
  *******************************************/
  class Player {
    float xpos;
    float ypos;
    float radius;
    color c = #0000ff;
 
    Player(float x, float y, float r, float s) {
      xpos = x;
      ypos = y;
      radius = r;
    }
 
    void display() {
      fill(c);
      ellipse(xpos, ypos, radius, radius);
    }
  }

  /*******************************************
  * Hazard Class
  * Holds all variables of a hazard object
  *******************************************/
  class Hazard {
    float xpos;
    float ypos;
    float radius;
    color c = #00ff00;
 
    Hazard(float x, float y, float r, float s) {
      xpos = x;
      ypos = y;
      radius = r;
    }
 
    void display(float hazardSpeed) {
      fill(c);
      ellipse(xpos, ypos, radius, radius);
      xpos -= hazardSpeed;
      ypos += sin((xpos / 30)) * hazardSpeed * 1.5;
    }
  }
  /*-------------------------------------------------------------*/
}

/********************************************************
* Class for the Game Menu Screen
*
*
*
*********************************************************/
class MenuScreen {
  String play = "play";
  String lb = "leaderboards"; // Strings to be displayed in menu
  String quit = "quit";
  String msg = "Press p for play, l for leaderboards, or q for quit";


  
  void display() {
    textSize(16);
    text(msg, 65, 30);
    textSize(32);
    text(play, 100, 100);
    text(lb, 100, 200);
    text(quit, 100, 300);
  }
}