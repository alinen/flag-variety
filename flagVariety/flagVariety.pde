// Useful notes: https://github.com/processing/processing/wiki/Advanced-OpenGL

float t = 0;
boolean pause = false;

PVector LERP(PVector a, PVector b, float t)
{
  float x = a.x + t * (b.x - a.x);
  float y = a.y + t * (b.y - a.y);
  float z = a.z + t * (b.z - a.z);
  return new PVector(x, y, z); 
}

float bernstein3(int i, float t)
{
  if (i == 0) return (1-t)*(1-t)*(1-t);
  else if (i == 1) return 3.0*(1-t)*(1-t)*t;
  else if (i == 2) return 3.0*(1-t)*t*t;
  else if (i == 3) return t*t*t;
  return 0.0;
}

PVector sampleBezier2D(float u, float v, PVector[][] ctrlPoints)
{
  float x = 0;
  float y = 0;
  float z = 0;
  for (int i = 0; i < 4; i++)
  {
    float bu = bernstein3(i,u);
    for (int j = 0; j < 4; j++)
    {
      float bv = bernstein3(j,v);
      x += bu * bv * ctrlPoints[i][j].x;
      y += bu * bv * ctrlPoints[i][j].y;
      z += bu * bv * ctrlPoints[i][j].z;
    }
  }
  return new PVector(x, y, z);
}

float segmentDistance(PVector pt, PVector a, PVector b)
{
  PVector ab = new PVector(); //<>//
  PVector.sub(b, a, ab);
  float L = ab.mag();
  ab.normalize();
  
  PVector pa = new PVector();
  PVector.sub(pt, a, pa);
  
  float dot = pa.dot(ab);
  if (dot <= 0) return pt.dist(a);
  if (dot >= L) return pt.dist(b);
  
  PVector closest = new PVector();
  closest.set(pt);
  closest.sub(ab.mult(dot));
  float distance = closest.mag();
  return distance;
}

float distanceTo(PVector pt, PVector a, PVector b, PVector c, PVector d)
{
  return Math.min(segmentDistance(pt, a, b), 
      Math.min(segmentDistance(pt, b, c), segmentDistance(pt, c, d)));
}

//  b ------------------ c
//  |                    |
//  |                    |
//  |                    |
//  |                    |
//  a ------------------ d
void drawBezierPatch(PVector a, PVector b, PVector c, PVector d, PVector n)
{
  // 1. compute control points
  PVector[][] ctrlPoints = new PVector[4][4];

  for (int i = 0; i <= 3; i++)
  {
    float fraci = i/3.0;
    for (int j = 0; j <= 3; j++)
    {
      float fracj = j/3.0;
      PVector pt1 = LERP(a, b, fraci);
      PVector pt2 = LERP(d, c, fraci);
      PVector pt = LERP(pt1, pt2, fracj);

      if (n != null)
      {
        //float blend = Math.max(Math.abs(fraci-0.5)*2.0, Math.abs(fracj-0.5)*2.0);
        float distanceToCenter = pt.dist(new PVector(0,150,0));
        float distanceToBorder = distanceTo(pt, a, b, c, d);
        float blend = Math.min(distanceToBorder, distanceToCenter/(distanceToBorder+distanceToCenter));
        PVector offset = LERP(n, new PVector(0,0,0), blend);
        float ctrlPtx = offset.x + pt.x;
        float ctrlPty = offset.y + pt.y;
        float ctrlPtz = offset.z + pt.z;
        //console.log(d+" "+ctrlPtx +" "+ctrlPty+" "+ctrlPtz);
        ctrlPoints[i][j] = new PVector(ctrlPtx, ctrlPty, ctrlPtz);
      }
      else
      {
        ctrlPoints[i][j] = pt;
      }
    }
  }

  // 2. draw mesh
  int numSubDivisions = 10;
  float dx = 1.0/numSubDivisions;

  for (int i = 0; i < numSubDivisions; i++)
  {
    beginShape(TRIANGLE_STRIP);
    for (int j = 0; j < numSubDivisions+1; j++)
    {
      PVector pt1 = sampleBezier2D(i*dx, j*dx, ctrlPoints);
      PVector pt2 = sampleBezier2D((i+1)*dx, j*dx, ctrlPoints);
      vertex(pt1.x, pt1.y, pt1.z);
      vertex(pt2.x, pt2.y, pt2.z);
    }
    endShape();
  }
}

void setup() 
{
   size(500, 500, P3D);
   print("TEST");
   
   
   segmentDistance(new PVector(-50,50,0),  new PVector(   0, 0, 0),  new PVector(-100, 100, 0)); //<>//
}

void mousePressed()
{
  pause = !pause;
}

void draw() 
{
  background(0);
  strokeWeight(1);
  
  pushMatrix();
  scale(1,-1,1);
  translate(250,-400,0);
  rotateY(t * 0.05);

  fill(255);
  stroke(255);
  pushMatrix();
  translate(0,0,0);
  sphere(5);
  popMatrix();

  fill(255,0,0, 128);
  drawBezierPatch(
    new PVector(   0, 0, 0), 
    new PVector(-100, 100, 0),
    new PVector( 100, 200, 0),
    new PVector( 100, 100, 0),
    new PVector(   0, 0, -100));

/*
  fill(0,255,0,128);
  drawBezierPatch(
    new PVector(0, 0, 0), 
    new PVector(-100, 100, 0),
    new PVector(-100, 200, 0),
    new PVector( 100, 100, 0),
    new PVector( 0,  0, 100));
*/
  fill(255,255,0,128);
  drawBezierPatch(
    new PVector(-100, 200, 0),
    new PVector(0,    300, 0), 
    new PVector(100,  200, 0),
    new PVector(100,  100, 0), null);

  drawBezierPatch(
    new PVector(0, 0, 0),
    new PVector(-100, 100, 0), 
    new PVector(-100, 200, 0),
    new PVector( 100, 100, 0), null);

  stroke(0,255,0,255);
  strokeWeight(10);
  beginShape(LINES);
  vertex(0,0,0);
  vertex(-100,100,0);
  endShape();

  stroke(255,0,0, 255);
  beginShape(LINES);
  vertex(0,0,0);
  vertex(100,100,0);
  endShape();

  popMatrix();

  if (!pause) t += 1;
}