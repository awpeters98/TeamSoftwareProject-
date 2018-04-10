import de.bezier.data.sql.*;
import processing.sound.*;

SoundFile menumusic;      //Main Menu background music
SoundFile bmusic;         // in-game bg music
SoundFile boom;
SoundFile mousehover;
//SoundFile mouseclick;   // sound when mouse is clicked

boolean pHovered;     // "Play" already hovered over
boolean lHovered;     // "Leaderboards" already hovered over
boolean oHovered;     // "Options" already hovered over (just in case)
boolean qHovered;     // "Quit" already hovered over
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
 
    // Create strings with sound file names
    String sMenuMusic = "MenuMusic.mp3";
    String sIGMusic = "ingameMusic.mp3";
    String sExplosion = "Explosion.mp3";
    String sMouseover = "laser.aiff";

    pHovered = false;
    lHovered = false;
    oHovered = false;
    qHovered = false;
    //Load a soundfile
    menumusic = new SoundFile(this, sMenuMusic);
    bmusic = new SoundFile(this, sIGMusic);
    boom = new SoundFile(this, sExplosion);
    mousehover = new SoundFile(this, sMouseover);
    mousehover.set( 0.5, 0, 1, 0 );

    menumusic.set(1,0,0.3,0);
    bmusic.set(1,0,0.4,0);

    // Play the file in a loop
    //menumusic.loop();

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

/*------------------------------------------ Game Screen Class -----------------------------------------------*/

class GameScreen {
  int score;
  int time;
  float distance;
  float lastHazardDistance;
  float lastPowerUp;
  float hazardSpeed;
 
  Player p1;
  ArrayList<Hazard> hazards; ArrayList<PowerUp> powerUps; ArrayList<ParticleSystem> explosions;
  String[] hazardTypes = {"sine", "straight", "zigzag"};
  String[] hazardShapes = {"circle", "rectangle", "wall", "spinner"};
 
  boolean paused, shielded;
 
  PFont f;
  PImage shield, speed;
  
  GameScreen() {
    time = millis();
    score = 0;
    hazardSpeed = 4.0;
    
    p1 = new Player(50.0, 350.0, 20.0, 2);
    hazards = new ArrayList<Hazard>();
    powerUps = new ArrayList<PowerUp>();
    explosions = new ArrayList<ParticleSystem>();
    
    paused = false; up = false; left = false; down = false; right = false;
    
    f = createFont("Arial", 26, true);
    textFont(f, 24);
  
    shield = loadImage("Shield.png");
  
    pop = new Popup();
}
  
 
  /*---------------------- Inner Classes For Game Screen ---------------------------*/  
  
  
  /*---------------------------- Particles ----------------------------------------*/

// A class to describe a group of Particles
// An ArrayList is used to manage the list of Particles 

  class ParticleSystem {
    ArrayList<Particle> particles;
    PVector origin;
    float lifespan;
    
    class Particle {
      PVector position;
      PVector velocity;

      Particle(PVector l) {
        velocity = new PVector(random(-1, 1), random(-2, 0));
        position = l.copy();
      }

      void run() {
        update();
        display();
      }

      // Method to update position
      void update() {
        position.add(velocity);
      }

      // Method to display
      void display() {
        stroke(0, lifespan);
        fill(0, lifespan);
        ellipse(position.x, position.y, 8, 8);
      }
    }
    
    ParticleSystem(PVector position) {
      lifespan = 255.0;
      origin = position.copy();
      particles = new ArrayList<Particle>();
      for (int i = 0; i < 40; i ++)
        particles.add(new Particle(origin));
    }

    void run() {
      for (int i = particles.size()-1; i >= 0; i--) {
        Particle p = particles.get(i);
        p.run();
      }
      lifespan -= 4.0;
    }
    
    // Is the particle system still useful?
    boolean isDead() {
      if (lifespan < 0.0) {
        return true;
      } else {
        return false;
      }
    }  
  }
  
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
          if (xradius % 2 == 1)
            yradius += PI / 30;
          else
            yradius -= PI / 30;
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
    boolean shielded;
    float speedMult, vSpeed, hSpeed;
    color c = #cccccc;
    
    /*******************************************
    * Player Consctructor
    * x-position y-position, radius, speed
    *******************************************/
    Player(float x, float y, float r, float s) {
      super(x, y, r, r, "rectangle");
      speedMult = s;
      vSpeed = 0; hSpeed = 0;
    }

   /*******************************************
   * Move Player
   *******************************************/
    void move() {
      if (!gameOver) {
        if(up)
          vSpeed = constrain(vSpeed + .1 * speedMult, -1, 1);
        if(down)
          vSpeed = constrain(vSpeed - .1 * speedMult, -1, 1);
        if(right)
          hSpeed = constrain(hSpeed + .1 * speedMult, -1, 1);
        if(left)
          hSpeed = constrain(hSpeed - .1 * speedMult, -1, 1);
          
        if (vSpeed < 0)
          vSpeed += .05;
        else
          vSpeed -= .05;
          
        if (hSpeed < 0)
          hSpeed += .05;
        else
          hSpeed -= .05;
          
        ypos = constrain(ypos - vSpeed * 4, 0, height - yradius);
        xpos = constrain(xpos + hSpeed * 4, 0, width - xradius);
      }
    }
 
    /*******************************************
    * Display Player
    * Calls: Player.move
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
    
  }
  
  /*-------------------------- Object Creation --------------------------------*/ 
 
 
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
       hazards.add(new Hazard(850.0, random(25, 775), random(30, 60), random(30, 60), 
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
    
      //After "Play" is clicked
      menumusic.stop();
      //bmusic.loop();    //background   
    
      distanceCheck();

      displayPowerUps();
      p1.display();
      displayHazards();
      displayParticles();
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
        if  (intersectCheck(p1, h))
          hazards.remove(i);
        //print(h.shape + "\n");
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
          powerUps.remove(i); 
          shielded = true;
          stroke(#ffffff);
        }
      }
    }
  }
  
  void displayParticles() {
    ParticleSystem ps; 
    for (int i = 0; i < explosions.size(); i ++) {
      ps = explosions.get(i);
      if (ps.isDead())
        explosions.remove(i);
      else
        ps.run();
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
     if (shielded) {
       shielded = false;
       explosions.add(new ParticleSystem(new PVector(p1.xpos, p1.ypos)));
       stroke(#000000);
       return true;
     }
     gameOver = true;
     paused = true;
     //After Collision
     bmusic.stop();
     boom.play();
     pop.display();
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
       return true;
    }
    else return false;
  }

  boolean spinnerCollision(GameObject player, GameObject hazard) {
    PVector points[]= new PVector[7];
    
    float theta = hazard.yradius + PI / 60;
    float endx1 = hazard.xpos + hazard.xradius * cos(theta);
    float endy1 = hazard.ypos + hazard.xradius * sin(theta);
    float endx2 = hazard.xpos - hazard.xradius * cos(theta);
    float endy2 = hazard.ypos - hazard.xradius * sin(theta);
    
    points[0] = new PVector(endx1, endy1);
    points[1] = new PVector(endx1 * 0.33, endy1 * 0.33);
    points[2] = new PVector(endx1 * 0.67, endy1 * 0.67);
    points[3] = new PVector((endx1 + endx2) * 0.5, (endy1 - endy2) * 0.5);
    points[4] = new PVector(endx2 * 0.33, endy2 * 0.33);
    points[5] = new PVector(endx2 * 0.67, endy2 * 0.67);
    points[6] = new PVector(endx2, endy2);
    
    for (int i = 0; i < points.length; i ++) {
      PVector point = points[i];
      if (pointInRect(point, player))
        return true;
    }
    
    return false;
  }
  
  boolean pointInRect(PVector point, GameObject rectangle) {
    if (point.x >= rectangle.xpos && point.x <= rectangle.xpos + rectangle.xradius) {
      if (point.y >= rectangle.ypos && point.y <= rectangle.ypos + rectangle.yradius) {
        return true;
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
    background(#a5a5a5);
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
    bmusic.stop();
    //menumusic.loop();
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
    background(#a5a5a5);
    int xxx = 0;   //filler int to suppress errors, fill in with real vals
    int yyy = 1;
    
    // Play
    if( 100 < mouseX && mouseX < 165 )
    {
      if( 70 < mouseY && mouseY <= 110 )
       {
        if( pHovered == false )
        {
        pHovered = true;
        lHovered = false;
        oHovered = false;
        qHovered = false;
        mousehover.play();
      }
    }
  }
 // Leaderboard
  if( 100 <= mouseX && mouseX <= 300 )
  {
    if( 175 <= mouseY && mouseY <= 200 )
    {
      if( lHovered == false )
      {
        pHovered = false;
        lHovered = true;
        oHovered = false;
        qHovered = false;
        mousehover.play();
      }
    }
  }
  // Options (not implemented)
  //if( 5 <= mouseX && mouseX <= 100 )
  //{
  //  if( 5 <= mouseY && mouseY <= 500 )
  //  {
  //    if( oHovered == false )
  //    {
  //      pHovered = false;
  //      lHovered = false;
  //      oHovered = true;
  //      qHovered = false;
  //      mousehover.play();
  //    }
  //  }
  //}
  // Quit
  if( 100 <= mouseX && mouseX <= 160 )
  {
    if( 270 <= mouseY && mouseY <= 310 )
    {
      if( qHovered == false )
      {
        pHovered = false;
        lHovered = false;
        oHovered = false;
        qHovered = true;
        mousehover.play();
      }
    }
  }

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
    background(#a5a5a5);
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
