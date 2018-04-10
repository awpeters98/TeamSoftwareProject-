import de.bezier.data.sql.*;
import processing.sound.*;
import controlP5.*;


boolean bplaying, fullsc;   // bg music playing, fullscreen mode

float gameHeight, gameWidth;

SoundFile menumusic;      //Main Menu background music
SoundFile bmusic;         // in-game bg music
SoundFile boom;
SoundFile mousehover;
//SoundFile mouseclick;   // sound when mouse is clicked

boolean isHovered;
MySQL mysql;
ControlP5 cp5;
GameScreen game;
MenuScreen menu;
Popup pop;
Leaderboard lb;
Options op;
int switcher = 0;
processing.core.PApplet p;


boolean up = false, down = false, right = false, left = false, gameOver = false, lbConnection = false, highScore = false, initInput = false;
String[] hazardTypes = {"sine", "straight", "zigzag"};
String initials = "";

controlP5.Button MainMenu, Play, Leaderboards, Quit, PlayAgain, Main_Menu, Options;
controlP5.Textfield Initials;
controlP5.Bang Submit;

void setup() {
    // Variable Initialization
  game = new GameScreen();
  lb = new Leaderboard();
  menu = new MenuScreen();
  pop = new Popup();
  cp5 = new ControlP5(this);
  op = new Options();
  surface.setResizable(true);
  fullsc = false;
  // Grabs this sketch id? for database connection. idk just works
  p = this;

  
  ellipseMode(RADIUS);
  size(800,600);
  gameHeight = 600;
  gameWidth = 800;
  background(#0069b1);
 
 //buttons
  MainMenu = cp5.addButton("MainMenu").hide();
  Play = cp5.addButton("Play").hide();
  Leaderboards = cp5.addButton("Leaderboards").hide();
  Quit = cp5.addButton("Quit").hide();
  PlayAgain = cp5.addButton("PlayAgain").hide();
  Main_Menu = cp5.addButton("Main_Menu").hide();
  Initials = cp5.addTextfield("Initials").hide();
  Submit = cp5.addBang("Submit").hide();
  Options = cp5.addButton("Options").hide();
   
    
    // Housekeeping
  lb.connect(this);  // Connects to this sketch id?
  ellipseMode(RADIUS);
  size(800,600);
  background(#0069b1);
    
  
    // Create strings with sound file names
    String sMenuMusic = "MenuMusic.mp3";
    String sIGMusic = "ingameMusic.mp3";
    String sExplosion = "Explosion.mp3";
    String sMouseover = "laser.aiff";

    //Load a soundfile
    menumusic = new SoundFile(this, sMenuMusic);
    bmusic = new SoundFile(this, sIGMusic);
    boom = new SoundFile(this, sExplosion);
    mousehover = new SoundFile(this, sMouseover);
    //print("Menu Music:" + menumusic.duration() + "\n");
    //print("BG Music:" + bmusic.duration() + "\n");
    mousehover.set( 0.5, 0, 1, 0 );

    menumusic.set(1,0,0.3,0);
    bmusic.set(1,0,0.4,0);   
    menumusic.loop();
}

void draw() {
  switch (switcher) {
    // Display menu here
    case 0: menu.display(); break;
    
    // Display game screen
    case 1: game.display();  break; 
    
    // Display Leaderboards here
    case 2: lb.display();  break;
    
     // Display Options here
    case 3: op.display();
  }
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
  if( key == 'f') {
    if( fullsc == false ) {
      surface.setSize(displayWidth, displayHeight);
      fullsc = true;
    } else {
      surface.setSize(800,600);
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


// Controls events when button/bang is clicked
void controlEvent(ControlEvent theEvent) {
  // Main Menu button from Leaderboards screen
  if (theEvent.getController().getName().equals("MainMenu")) {
    switcher = 0;
    MainMenu.hide();
  }
  // Play button from Main Menu screen
  if (theEvent.getController().getName().equals("Play")) {
    switcher = 1;
    Play.hide();
    Leaderboards.hide();
    Quit.hide();
  }
  // Leaderboards button from Main Menu screen
  if (theEvent.getController().getName().equals("Leaderboards")) {
    switcher = 2;
    Leaderboards.hide();
    Play.hide();
    Quit.hide();    
  }
  // Quit button from Main Menu screen
  if (theEvent.getController().getName().equals("Quit")) {
    lb.disconnect();
    exit();
  }
  // Play Again button from Popup screen
  if (theEvent.getController().getName().equals("PlayAgain")) {
    PlayAgain.hide();
    Main_Menu.hide();
    Initials.hide();
    Submit.hide();
    gameOver = false;
    highScore = false;
    initials = "";
    game = new GameScreen();
    switcher = 1;
  }
  // Main Menu button from Popup screen
  if (theEvent.getController().getName().equals("Main_Menu")) {
    PlayAgain.hide();
    Main_Menu.hide();
    Initials.hide();
    Submit.hide();
    gameOver = false;
    highScore = false;
    initials = "";
    game = new GameScreen();
    switcher = 0;
  }
  // Submit bang from Popup screen
  if (theEvent.getController().getName().equals("Submit")) {
    initials = Initials.getText();
    Initials.clear();
    lb.updateScore(game.score, initials);
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
    
    gameHeight = height;
    gameWidth = width;
    
    p1 = new Player(50.0, (gameHeight / 2) - 25, gameHeight / 40.0, 2);
    hazards = new ArrayList<Hazard>();
    powerUps = new ArrayList<PowerUp>();
    explosions = new ArrayList<ParticleSystem>();
    
    paused = false; gameOver = false; up = false; left = false; down = false; right = false;
    
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
      for (int i = 0; i < 50; i ++)
        particles.add(new Particle(origin));
    }

    void run() {
      for (int i = particles.size()-1; i >= 0; i--) {
        Particle p = particles.get(i);
        p.run();
      }
      lifespan -= 4.0;
    }
    
    // Is the particle still useful?
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
          rect(xpos, ypos + (gameHeight * 5) / 16, 30, gameHeight - ypos - (gameHeight * 5) / 16);
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
          
        if (vSpeed < -0.05)
          vSpeed += .03;
        else if (vSpeed > 0.05)
          vSpeed -= .03;
        else
          vSpeed = 0;
          
        if (hSpeed < -0.05)
          hSpeed += .03;
        else if (hSpeed > 0.05)
          hSpeed -= .03;
        else
          hSpeed = 0;
          
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
    powerUps.add(new PowerUp(width + 300, random(100, height - 150), 30.0, "shield")); 
  }
  
  void createHazard() {
    String shape = hazardShapes[(int)random(0,4)];
    
    switch (shape) {
     case "rectangle":
       hazards.add(new Hazard(width + 50, random(25, height - 55), random(30, 60), random(30, 60), 
                    hazardTypes[(int)random(0,3)], shape));
       break;
     case "circle":
       hazards.add(new Hazard(width + 50, random(25, height - 25), 30.0, 30.0, 
                    hazardTypes[(int)random(0,3)], shape));
       break;
     case "wall":
       hazards.add(new Hazard(width + 50, random(0, height - 250), 30.0, 30.0, 
                    "straight", shape));
       break;
     case "spinner":
       hazards.add(new Hazard(width + 50, random(25, height - 25), random(50, 100), 0, 
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
    float distance = sqrt(sq(player.xpos + player.xradius / 2 - hazard.ypos) + sq(player.ypos + player.yradius / 2 - hazard.ypos));
    if (distance > hazard.xradius + player.xradius * sqrt(2)) {
      return false;
    }
    println("true");
    
    PVector points[]= new PVector[7];
    
    float theta = hazard.yradius + PI / 60;
    float endx1 = hazard.xpos + hazard.xradius * cos(theta);
    float endy1 = hazard.ypos + hazard.xradius * sin(theta);
    float endx2 = hazard.xpos - hazard.xradius * cos(theta);
    float endy2 = hazard.ypos - hazard.xradius * sin(theta);
    
    points[0] = new PVector(endx1, endy1);
    points[1] = new PVector(endx1 * 0.33, endy1 * 0.33);
    points[2] = new PVector(endx1 * 0.67, endy1 * 0.67);
    points[3] = new PVector(hazard.xpos, hazard.ypos);
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
    boom.play();
    // let boom play for a 1.5 s before switching screens
    int tstamp = millis();
    while( (millis() - tstamp) < 1555 ) {
      
      continue;
    }

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
    
    Play.setPosition(100, 100).show();
    Leaderboards.setPosition(100, 200).show();
    Options.setPosition(100, 300).show();
    Quit.setPosition(100, 400).show();
    if (cp5.isMouseOver(cp5.getController("Play")) || cp5.isMouseOver(cp5.getController("Quit")) || cp5.isMouseOver(cp5.getController("Leaderboards")) || cp5.isMouseOver(cp5.getController("Options") ) ) {
      if( isHovered == false ) {
        isHovered = true;
        mousehover.play();
    }
  } else {
    isHovered = false;
  }
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

class Options {
  Options() {
    
  }
  
  void display() {
    // Volume - slider
    // Fullscreen - button
    // Color scheme - radio
    // Sound/Music - slider
    // Difficulty - radio
  }
}

// -------------------------- Player Movement -----------------------------------
