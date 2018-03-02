import de.bezier.data.sql.*;
  
MySQL mysql;
processing.core.PApplet p;

GameScreen game;
MenuScreen menu;
Leaderboard lb;
int switcher = 0;

boolean up = false, down = false, right = false, left = false;
String[] hazardTypes = {"sine", "straight", "zigzag"};

void setup() {
  game = new GameScreen();
  lb = new Leaderboard();
  menu = new MenuScreen();
  
  // Grabs this sketch id? for database connection. idk just works
  p = this;
  
  ellipseMode(RADIUS);
  size(800,600);
  background(#0069b1);
 
   
}

void draw() {
  switch (switcher) {
    // Display menu here
    case 0: menu.display(); break;
    
    // While the game is happening, display game screen
    case 1: if (true) game.display(); break;
    
    // Display Leaderboards here
    case 2: lb.display(); break;
  }
}

void mousePressed() {
  if (switcher == 0 && mouseX > 100 && mouseX < 165 && mouseY > 70 && mouseY < 110) {
    switcher = 1;
  }
  if (switcher == 0 && mouseX > 100 && mouseX < 300 && mouseY > 175 && mouseY < 200) {
    switcher = 2;
    lb.connect(p);
  }
  if (switcher == 0 && mouseX > 100 && mouseX < 160 && mouseY > 270 && mouseY < 310) {
    exit();
    lb.disconnect();
  }
  if (switcher == 2 && mouseX > 300 && mouseX < 555 && mouseY > 545 && mouseY < 570) {
    switcher = 0;
  }
  // play: 100 < x < 165, 70 < y < 110
  // leaderboards: 100 < x < 300, 175 < y < 200
  // quit: 100 < x < 160, 270 < y < 310
  println(mouseX, mouseY);
}

void keyPressed() {
      switch (key) {
        case 'w':
          up = true;
          break;
        case 's':
          down = true;
          break;
        case 'a':
          left = true;
          break;
        case 'd':
          right = true;
      }
    }

     void keyReleased() {
      switch (key) {
        case 'w':
          up = false;
          break;
        case 's':
          down = false;
          break;
        case 'a':
          left = false;
          break;
        case 'd':
          right = false;
      }  
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
    
    p1 = new Player(50.0, 350.0, 20.0, 4);
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
      hazards.add(new Hazard(850.0, random(25, 775), 30.0, hazardTypes[(int)random(0,3)]));
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
    float s;
    color c = #0000ff;
    
    
 
    Player(float x, float y, float r, float s) {
      xpos = x;
      ypos = y;
      radius = r;
      this.s = s;
    }
    
    
    
    //MOVE PLAYER
    void moveUp() {
      ypos = constrain(ypos - s, 0 + radius, height - radius);
    }
    void moveDown() {
      ypos = constrain(ypos + s, 0 + radius, height - radius);
    }
    void moveLeft() {
      xpos = constrain(xpos - s, 0 + radius, width - radius);
    }
    void moveRight() {
      xpos = constrain(xpos + s, 0 + radius, width - radius);
    }
 
    void display() {
      //PlayerMovement Start
      if(up)
        moveUp();
      if(down)
        moveDown();
      if(right)
        moveRight();
      if(left)
        moveLeft();
      //Player Movement End

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
    String type;
    color c = #00ff00;
 
    Hazard(float x, float y, float r, String type) {
      xpos = x;
      ypos = y;
      radius = r;
      this.type = type;
    }
 
    void display(float hazardSpeed) {
      fill(c);
      switch (type) {
        case "sine":
          xpos -= hazardSpeed;
          ypos += sin((xpos / 30)) * hazardSpeed * 1.5;
          break;
        case "straight":
          xpos -= hazardSpeed;
          break;
        case "zigzag":
          xpos -= hazardSpeed;
          if (xpos % 400 < 200)
            ypos += 4;
          else
            ypos -= 4;
      }
      ellipse(xpos, ypos, radius, radius);
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

  
  void display() {
    background(#0069b1);
    textSize(32);
    text(play, 100, 100);
    text(lb, 100, 200);
    text(quit, 100, 300);
  }
}

/********************************************************
* Class for the Leaderboard Screen
*
*
*
*********************************************************/
class Leaderboard {
  String inits;
  int pts;
  
  /********************************************************
  * Class for connecting to an SQL database
  * 
  *********************************************************/
  void connect(processing.core.PApplet papplet) {
   
    String user = "cs3425gr";
    String pass = "cs3425gr";
    String db = "aplyons";
    mysql = new MySQL(papplet, "classdb.it.mtu.edu", db, user, pass);
 
    if (!mysql.connect()) {
      println("Connection failed, leaderboards unavailable");
    }
  }
  
  void disconnect() {
    mysql.close();
  }
  
  void display() {
    // Variable declaration
    int entry = 1;
    int yOffset = 0;
    int xOffset = 0;
    
    // Initialize screen and display text
    background(#0069b1);
    textSize(30);
    text("HIGH SCORES", 300, 30);
    text("Back to main menu", 300, 570);
    
    // Grab entries from db and display
    mysql.query("select * from Leaderboard order by points desc");
    for (int j = 0; j < 2; j++) {
      for (int i = 0; i < 10; i++) {
        if (mysql.next()) {
          
          String str = (entry + ": " + mysql.getString(1) + " " + mysql.getInt(2));
          text(str, 100 + xOffset, 100 + yOffset);
        }
        else {
          String str = entry + ": ";
          text(str, 100 + xOffset, 100 + yOffset);
        }
        entry++;
        yOffset += 30;
      }
      yOffset = 0;
      xOffset = 400;
    }
  }
}

// -------------------------- Player Movement -----------------------------------