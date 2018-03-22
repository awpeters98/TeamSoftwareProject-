float angle = 0;
float centerx = 200;
float centery = 200;
float length = 50;

void setup() {
  size(400, 400);
  noStroke();
  fill(255);
}

void draw() {
  background(#cecece);
 
  angle += PI / 90;
 
  fill(#2f2f2f);
  beginShape();
    vertex(-(centerx + length * sin(angle + PI / 30)), -(centery + length * cos(angle + PI / 30)));
    vertex(centerx + length * sin(angle + PI / 30), centery + length * cos(angle + PI / 30));
    vertex(-(centerx + length * sin(angle)), -(centery + length * cos(angle)));
    vertex(centerx + length * sin(angle), centery + length * cos(angle));
  endShape();
 
}