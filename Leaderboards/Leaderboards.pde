import de.bezier.data.sql.*;
  
MySQL mysql;
processing.core.PApplet p;

GameScreen game;
MenuScreen menu;
Popup pop;
Leaderboard lb;
int switcher = 0;

boolean up = false, down = false, right = false, left = false, gameOver = false, lbConnection = false, highScore = false, initInput = false;
String[] hazardTypes = {"sine", "straight", "zigzag"};
String initials = "";

void setup() {
  game = new GameScreen();
  lb = new Leaderboard();
  menu = new MenuScreen();
  pop = new Popup();
  
  // Grabs this sketch id? for database connection. idk just works
  p = this;
  lb.connect(p);
  
  ellipseMode(RADIUS);
  size(800,600);
  background(#0069b1);
 
   
}

void draw() {
  switch (switcher) {
    // Display menu here
    case 0: menu.display(); break;
    
    // Display game screen
    case 1: game.display(); break;
    
    // Display Leaderboards here
    case 2: lb.display(); break;
  }
}

void mousePressed() {
  if (switcher == 0 && mouseX > 100 && mouseX < 165 && mouseY > 70 && mouseY < 110) {
    switcher = 1;  // Play button from Main Menu
  }
  if (switcher == 0 && mouseX > 100 && mouseX < 300 && mouseY > 175 && mouseY < 200) {
    switcher = 2;  // Leaderboards button from Main Menu
    
  }
  if (switcher == 0 && mouseX > 100 && mouseX < 160 && mouseY > 270 && mouseY < 310) {
    exit();  // Quit button from Main Menu
    lb.disconnect();
  }
  if (switcher == 2 && mouseX > 300 && mouseX < 555 && mouseY > 545 && mouseY < 570) {
    switcher = 0;  // Main Menu button from Leaderboards
  }
  if (switcher == 1 && gameOver && mouseX > 100 && mouseX < 250 && mouseY > 275 && mouseY < 300) {
    game = new GameScreen();  // Play again button from Popup
    gameOver = false;
    highScore = false;
    switcher = 1;
    initials = "";
  }
  if (switcher == 1 && gameOver && mouseX > 100 && mouseX < 260 && mouseY > 375 && mouseY < 400) {
    switcher = 0;  // Main Menu button from Popup
    gameOver = false;
    highScore = false;
    game = new GameScreen();
    initials = "";
  }
  if (switcher == 1 && gameOver && highScore && mouseX > 100 && mouseX < 380 && mouseY > 175 && mouseY < 200) {
    initials = "";  // Click to enter initials if you got a high score
    initInput = true;
  }
  if (switcher == 1 && gameOver && highScore && mouseX > 450 && mouseX < 745 && mouseY > 175 && mouseY < 200) {
    lb.updateScore(game.score, initials);
  }
  println(mouseX, mouseY);
}

void keyPressed() {
  if (!gameOver) {
      switch (key) {
        case 'w':
          up = true; break;
        case 's':
          down = true; break;
        case 'a':
          left = true; break;
        case 'd':
          right = true; break;
      }
  }
}

void keyReleased() {
  if (!gameOver) {
    switch (key) {
      case 'w':
        up = false; break;
      case 's':
        down = false; break;
      case 'a':
        left = false; break;
      case 'd':
        right = false;
    }
  }
}

void keyTyped() {
  if (initInput) {
    if (initials.length() < 3) {
      if ((key >= 'A' && key <= 'Z') || (key >= 'a' && key <= 'z')) {
        initials += key;
      }
    }
    else {
      lb.updateScore(game.score, initials);
    }
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
  float distance;
  float lastHazardDistance;
  float lastPowerUp;
  float hazardSpeed;
 
  Player p1;
  ArrayList<Hazard> hazards; ArrayList<PowerUp> powerUps;
  String[] hazardTypes = {"sine", "straight", "zigzag"};
  String[] hazardShapes = {"circle", "rectangle", "wall", "spinner"};
 
  boolean paused, shielded;
 
  PFont f;
  PImage shield, speed;
  
  GameScreen() {
    time = millis();
    score = 0;
    hazardSpeed = 4.0;
    
    p1 = new Player(50.0, 350.0, 20.0, 4);
    hazards = new ArrayList<Hazard>();
    
    paused = false; gameOver = false; up = false; down = false; right = false; left = false;
    
    f = createFont("Arial", 26, true);
    textFont(f, 24);
    
    shield = loadImage("Shield.png");
  }
 
  /*---------------------- Inner Classes For Game Screen ---------------------------*/ 
  
  /* ----------------- Game Objects --------------------*/
  
  class GameObject {
    float xpos, ypos, xradius, yradius;
    String shape;
    
    /*******************************************
    * Game Object Constructor
    *******************************************/
    GameObject(float xpos, float ypos, float xradius, float yradius, String shape) {
      this.xpos = xpos;
      this.ypos = ypos;
      this.xradius = xradius;
      this.yradius = yradius;
      this.shape = shape;
    }
    
    /*******************************************
    * Displays Game Objects
    *******************************************/
    void display() {
      switch (shape) {
        case "rectangle":
          rect(xpos, ypos, xradius, yradius);
          break;
        case "circle":
          ellipse(xpos, ypos, xradius, xradius);
          break;
        case "wall":
          rect(xpos, 0, 30, ypos);
          rect(xpos, ypos + 250, 30, height - ypos - 250);
          break;
        case "spinner":
          // xradius acts as radius
          // yradius acts as angle
          beginShape();
            vertex(xpos + xradius * cos(yradius), ypos + xradius * sin(yradius));
            vertex(xpos + xradius * cos(yradius + PI / 30), ypos + xradius * sin(yradius + PI / 30));
            vertex(xpos + -(xradius * cos(yradius)), ypos - xradius * sin(yradius));
            vertex(xpos - xradius * cos(yradius + PI / 30), ypos - xradius * sin(yradius + PI / 30));       
          endShape();
          yradius += PI / 30;
      }
    }
  }

  /* ----------------- Power-Up Object ------------------*/
  class PowerUp extends GameObject {
    String type;    
    
    PowerUp(float x, float y, float r, String type) {
      super(x, y, r, r, "rectangle");
      this.type = type;
    }
    
    void display() {
      xpos -= hazardSpeed;
      image(shield, xpos, ypos, xradius, yradius);
    }    
  }
  
  /* ----------------- Player Object --------------------*/
  
  class Player extends GameObject {
    float s;
    color c = #cccccc;
    
    /*******************************************
    * Player Consctructor
    * x-position y-position, radius, speed
    *******************************************/
    Player(float x, float y, float r, float s) {
      super(x, y, r, r, "rectangle");
      this.s = s;
    }

   /*******************************************
   * Mover Player
   *******************************************/
    void move() {
      if (!gameOver) {
        if(up)
          ypos = constrain(ypos - s, 0, height - yradius);
        if(down)
          ypos = constrain(ypos + s, 0, height - yradius);
        if(right)
          xpos = constrain(xpos + s, 0, width - xradius);
        if(left)
          xpos = constrain(xpos - s, 0, width - xradius);
      }
    }
 
    /*******************************************
    * Display Player
    * Calls: Player.move, GameObject.display
    *******************************************/
    void display() {
      move();
      fill(c);
      super.display();
    }
  }

  /* ----------------- Hazard Objects --------------------*/
  
  class Hazard extends GameObject {
    String path;
    color c = #2e2e2e;
 
    /*******************************************
    * Hazard Constructor
    * x-position, y-position, x-radius, y-radius,
    *  path, shape
    *******************************************/
    Hazard(float x, float y, float xr, float yr, String path, String shape) {
      super(x, y, xr, yr, shape);
      this.path = path;
    }
    
    /*******************************************
    * Moves Hazard
    *******************************************/
    void moveHazard(float hazardSpeed) {
      switch (path) {
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
    }
      
    /*******************************************
    * Displays Hazard
    *******************************************/
    void display(float hazardSpeed) {
      fill(c);
      moveHazard(hazardSpeed);      
      super.display();
    }
    
    void hazardMovement(float hazardSpeed) {
       
    }
    
  }
  
  /*-------------------------- Hazard Creation --------------------------------*/ 
 
 
  /*****************************************************************
  * Checks the time since last object has been generated.
  * If delta(time) >= 1/2 second, create new hazard off screen
  * and increase the hazard speed, then reset time to current time.
  *
  * @returns true if new hazard is created
  ******************************************************************/
  boolean distanceCheck() {
    distance += hazardSpeed;
    
    if (distance - lastPowerUp > 2000) {
      createPowerUp();
      lastPowerUp = distance;
    }
    
    if (distance - lastHazardDistance > 500) {
      hazardSpeed += .1;
      createHazard();
      lastHazardDistance = distance;
      return true;
    }
    return false;
  }
  
  void createPowerUp() {
    powerUps.add(new PowerUp(1100.0, random(100, height - 150), 30.0, "shield")); 
  }
  
  void createHazard() {
    String shape = hazardShapes[(int)random(0,4)];
    
    switch (shape) {
     case "rectangle":
       hazards.add(new Hazard(850.0, random(25, 775), 30.0, 30.0, 
                    hazardTypes[(int)random(0,3)], shape));
       break;
     case "circle":
       hazards.add(new Hazard(850.0, random(25, 775), 30.0, 30.0, 
                    hazardTypes[(int)random(0,3)], shape));
       break;
     case "wall":
       hazards.add(new Hazard(850.0, random(0, height - 250), 30.0, 30.0, 
                    "straight", shape));
       break;
     case "spinner":
       hazards.add(new Hazard(850.0, random(25, 775), random(50, 100), 0, 
                    "straight", shape));
       break;
     default:
    }
  }
  
  /******************************************************
  * Displays players and hazards during the game screen
  *
  * Calls GameScreen.displayHazards, Player.display, GameScreen.timeCheck
  *******************************************************/
  void display() {
    if (!gameOver) {
      background(#a5a5a5);
    
      text(score, 10, 25);
    
      distanceCheck();

      displayHazards();
      p1.display();
    }
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
      if ( h.xpos < 0 - h.xradius) {
        hazards.remove(i);
        score += 100 * (int)hazardSpeed / 4;
      } else {
        h.display(hazardSpeed);
        if (intersectCheck(p1, h))
          hazards.remove(i);
      }
    }
  }
  
  void displayPowerUps() {
    PowerUp p;
    for (int i = 0; i < powerUps.size(); i++) {
      p = powerUps.get(i);
      if ( p.xpos < 0 - p.xradius) {
        powerUps.remove(i);
      } else {
        p.display();
        if (twoRectangleCollision((GameObject)p1, (GameObject)p)) {
          switch (p.type) {
            case "shield":
              shielded = true;
              break;
          }
          powerUps.remove(i); 
        }
      }
    }
  }
  
  /* ------------------------- Collision Detection ----------------------- */
  
  boolean intersectCheck(Player p, Hazard h) {
    boolean intersect;

    switch (h.shape) {
      case "rectangle":
        intersect = twoRectangleCollision(p, h);
        break;
      case "circle":
        intersect = rectCircCollision(p, h);     
        break;
      case "wall":
        intersect = wallCollision(p, h);
        break;
      case "spinner": 
        intersect = spinnerCollision(p, h);
        break;
      default:
        intersect = false;
    };
    
    if (intersect) {
      if (!shielded) {
        gameOver = true;
        paused = true;
        pop.display();
        return false;
      } else {
        shielded = false;
        return true;
      }
    }
    return false;
  }
  
  /************************************************
  * Checks to see if a circular hazard and
  * the player object are intersecting
  *
  * Returns true if they are and pauses the game
  *************************************************/
  boolean circleIntersects(Player p, Hazard h) {
    float difX = h.xpos - p.xpos;
    float difY = h.ypos - p.ypos;
    
    float dist = sqrt(sq(difX) + sq(difY));
    
    if (dist < h.xradius + p.xradius) {
       p.c = #ff0000;
       hazardSpeed = 0;
       paused = true;
       gameOver = true;
       pop.display();
       return true;
    }
    else return false;
  }

  boolean spinnerCollision(GameObject player, GameObject hazard) {
    float px1 = player.xpos; float py1 = player.ypos;
    float px2 = player.xpos + player.xradius; float py2 = player.ypos;
    float px3 = player.xpos; float py3 = player.ypos + player.yradius;
    float px4 = player.xpos + player.xradius; float py4 = player.ypos + player.yradius;
    
    float hx1 = hazard.xpos + hazard.xradius * cos(hazard.yradius); float hy1 = hazard.ypos + hazard.xradius * sin(hazard.yradius);
    float hx2 = hazard.xpos + hazard.xradius * cos(hazard.yradius + PI / 30); float hy2 = hazard.ypos + hazard.xradius * sin(hazard.yradius + PI / 30);
    float hx3 = hazard.xpos + -(hazard.xradius * cos(hazard.yradius)); float hy3 = hazard.ypos - hazard.xradius * sin(hazard.yradius);
    float hx4 = hazard.xpos - hazard.xradius * cos(hazard.yradius + PI / 30); float hy4 = hazard.ypos - hazard.xradius * sin(hazard.yradius + PI / 30);
    
    float xs[] = { px1, px2, px3, px4};
    float ys[] = { py1, py2, py3, py4};
    
    for (int i = 0; i < 4; i++) {
      float denominator = ((xs[(i + 1) % 3] - xs[i]) * (hy2 - hy1)) - ((ys[(i + 1) % 3] - ys[i]) * (hx2 - hx1));
      float numerator1 = ((ys[(i + 1) % 3] - hy1) * (hx2 - hx1)) - ((xs[i] - hx1) * (hy2 - hy1));
      float numerator2 = ((xs[i] - hy1) * (xs[(i + 1) % 3] - xs[i])) - ((xs[i] - hx1) * (ys[(i + 1) % 3] - ys[i]));
      if (denominator != 0) { 
        float r = numerator1 / denominator;
        float s = numerator2 / denominator;
        if (r >= 0 && r <= 1 && s >= 0 && s <= 1) {
          return true; 
        }
      }
    }
    
    for (int i = 0; i < 4; i++) {
      float denominator = ((xs[(i + 1) % 3] - xs[i]) * (hy4 - hy3)) - ((ys[(i + 1) % 3] - ys[i]) * (hx4 - hx3));
      float numerator1 = ((ys[(i + 1) % 3] - hy3) * (hx4 - hx3)) - ((xs[i] - hx1) * (hy4 - hy3));
      float numerator2 = ((xs[i] - hy3) * (xs[(i + 1) % 3] - xs[i])) - ((xs[i] - hx3) * (ys[(i + 1) % 3] - ys[i]));
      if (denominator != 0) { 
        float r = numerator1 / denominator;
        float s = numerator2 / denominator;
        if (r >= 0 && r <= 1 && s >= 0 && s <= 1) {
          return true; 
        }
      }
    }
    return false;
  }
  
  /************************************************
  * Checks if a wall hazard and the player are intersecting
  *
  * Returns true if they are and pauses the game
  *************************************************/
  boolean wallCollision(GameObject player, GameObject hazard) {
    if (player.xpos + player.xradius > hazard.xpos && player.xpos < hazard.xpos + 30) {
      if (player.ypos < hazard.ypos || player.ypos + player.yradius > hazard.ypos + 250) {
        return true;
      }
    }
    return false;
  }
  
  boolean twoRectangleCollision(GameObject player, GameObject hazard) {
    float px, py, pxrad, pyrad, hx, hy, hxrad, hyrad;
    px = player.xpos; py = player.ypos; pxrad = player.xradius; pyrad = player.yradius;
    hx = hazard.xpos; hy = hazard.ypos; hxrad = hazard.xradius; hyrad = hazard.yradius;
    
    
    if ( hx > px + pxrad || hx + hxrad < px || hy + hyrad < py || hy > py + pyrad) {
      return false;
    }
    else {
      return true;
    }
  }
  
  boolean rectCircCollision(GameObject r, GameObject c) {
    float detectPointx, detectPointy;
    float cx, cy, cr, rx, ry; 
    
    cx = c.xpos; cy = c.ypos; cr = c.xradius;
    rx = r.xpos; ry = r.ypos;
    
    if(cx < rx)
      detectPointx = rx;
    else if ( cx > rx + r.xradius)
      detectPointx = rx + r.xradius;
    else
      detectPointx = cx;
    
    if(cy < ry)
      detectPointy = ry;
    else if ( cy > ry + r.yradius)
      detectPointy = ry + r.yradius;
    else
      detectPointy = cy;

   if (sqrt(sq(detectPointx - cx) + sq(detectPointy - cy)) < c.xradius)
     return true;
   else 
     return false;
  }
}

/*******************************************
* Popup Class
* Holds all variables of the popup menu after game
*******************************************/
class Popup {
  Popup() {
    
  }
  
  void display() {
    background(#0069b1);
    if (lbConnection) {
      if (lb.scoreCheck(game.score)) {
        highScore = true;
        textSize(32);
        text("You Made The Leaderboards with " + game.score + " points!", 100, 50);
        text("Click to enter initials", 100, 200);
        text("Click to submit score", 450, 200);
        text(initials, 400, 100);        
        text("Play again", 100, 300);
        text("Main menu", 100, 400);
      }
      else {
        textSize(32);
        text("Your scored " + game.score + " points!", 100, 50);
        text("Play again", 100, 300);
        text("Main menu", 100, 400);
      }
    }
    else {
      textSize(32);
      text("Your scored " + game.score + " points!", 100, 50);
      text("Play again", 100, 300);
      text("Main menu", 100, 400);
      textSize(20);
      text("Leaderboards unavailable", 500, 50);
    }
  }
}

/********************************************************
* Class for the Game's Menu Screen
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
  * method for connecting to an SQL database
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
    else {
      lbConnection = true;
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
  
  boolean scoreCheck(int s) {
    boolean result = false;
    mysql.query("select count(*) from Leaderboard");
    if (mysql.next()) {
      if (mysql.getInt(1) < 20) {
        result = true;
      }
      else {
        mysql.query("select distinct min(points) from Leaderboard");
          if (mysql.next()) {
            if (s > mysql.getInt(1)) {
              result = true;
            }
            else {
              result = false;
            }
          }
      }
    }
    return result;
  }
  
  void updateScore(int s, String init) {
    mysql.query("select count(*) from Leaderboard");
    if (mysql.next()) {
      if (mysql.getInt(1) < 20) {
        mysql.query("insert into Leaderboard values('" + init + "'," + s + ")");
      }
      else {
        mysql.query("select distinct min(points) from Leaderboard");
          if (mysql.next()) {
            if (s > mysql.getInt(1)) {
              mysql.query("delete from Leaderboard where points = (select points from (select distinct min(points) as minPoints from Leaderboard) as L)");
              mysql.query("insert into Leaderboard values('" + init + "'," + s + ")");
            }
          }
      }
    }
  }
}

// -------------------------- Player Movement -----------------------------------