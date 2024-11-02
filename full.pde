import websockets.*;
import processing.video.*;
import processing.sound.*;


float tileSize = 100;
float time = 0;
float energyOffset = 0;
float energyLevel = 0;  // Controls nature size based on energy
float maxEnergy = 100;
float minEnergy = 0;

color[] natureColors = {
  color(76, 175, 80),    // Green
  color(67, 160, 71),    // Darker green
  color(102, 187, 106)   // Lighter green
};
color[] energyColors = {
  color(255, 107, 53),   // Orange
  color(255, 152, 0),    // Amber
  color(255, 193, 7)     // Yellow
};

Amplitude amplitude;
AudioIn input;
WebsocketServer server;

void setup() {
  fullScreen();
  background(0);
  
  // Initialize sound components
  input = new AudioIn(this, 0);
  input.start();
  
  amplitude = new Amplitude(this);
  amplitude.input(input);
  
  server = new WebsocketServer(this, 8080, "/sv");
}

void commsEvent(String input) {
  if (input == null) return;
  if (input.startsWith("e: ")) {
    println("Received energy event " + input.substring(3));
    float readEnergy = Float.parseFloat(input.substring(3));
    println(readEnergy);
    energyLevel = readEnergy;
  }
  println(input);
}

void webSocketServerEvent(String input){
  println(input);
  commsEvent(input);
}

void draw() {
  background(0);
  // println(energyLevel);
  
  // Update energy level based on detected sound
  // energyLevel = constrain(amplitude.analyze() * maxEnergy, minEnergy, maxEnergy);
  
  // Update animation variables
  time += 0.02;
  energyOffset = map(energyLevel, minEnergy, maxEnergy, 5, 20);  // Increase offset with energy
  
  // Create tessellation by repeating the pattern
  for (float x = 0; x < width + tileSize; x += tileSize) {
    for (float y = 0; y < height + tileSize; y += tileSize) {
      drawTile(x, y);
    }
  }
}

void drawTile(float x, float y) {
  pushMatrix();
  
  // Translate to the center of each tile and then apply rotation
  translate(x + tileSize / 2, y + tileSize / 2);
  
  // Apply rotation based on `time` and energy level for varying speed
  float rotationAngle = time * 0.5; // Adjust rotation speed here if needed
  rotate(rotationAngle);
  
  // Offset back to the top-left of the tile for drawing
  translate(-tileSize / 2, -tileSize / 2);
  
  // Draw nature and energy elements
  drawNatureElements();
  drawEnergyElements();
  
  popMatrix();
}
void drawNatureElements() {
  // Adjust nature size inversely proportional to energy level
  for (int i = 0; i < 3; i++) {
    float scale = 1.5 - map(energyLevel, minEnergy, maxEnergy, 0.5, 1.5);
    
    // Enhanced rotation animation
    float baseRotation = time * 0.5;  // Continuous rotation
    float wobble = sin(time * 2 + i) * 15;  // Wobbling effect
    float windEffect = sin(time * 0.3) * 10;  // Slow wind effect
    float rotation = baseRotation + wobble + windEffect;
    
    pushMatrix();
    translate(tileSize / 2, tileSize / 2);
    rotate(radians(rotation));
    scale(scale);  // Apply scaling for energy relationship
    translate(-tileSize / 2, -tileSize / 2);
    
    fill(natureColors[i], 180);
    noStroke();
    
    // Main kite with curved edges
    beginShape();
    vertex(tileSize / 2, 0);
    bezierVertex(tileSize * 0.7, tileSize * 0.3, 
                 tileSize * 0.7, tileSize * 0.3, 
                 tileSize * 0.7, tileSize / 2);
    bezierVertex(tileSize * 0.7, tileSize * 0.7, 
                 tileSize * 0.6, tileSize * 0.8, 
                 tileSize / 2, tileSize);
    bezierVertex(tileSize * 0.4, tileSize * 0.8, 
                 tileSize * 0.3, tileSize * 0.7, 
                 tileSize * 0.3, tileSize / 2);
    bezierVertex(tileSize * 0.3, tileSize * 0.3, 
                 tileSize * 0.3, tileSize * 0.3, 
                 tileSize / 2, 0);
    endShape(CLOSE);
    
    // Add vein patterns
    stroke(natureColors[i], 100);
    strokeWeight(1);
    float centerX = tileSize / 2;
    float centerY = tileSize / 2;
    for (int j = 0; j < 5; j++) {
      float angle = j * PI / 4 + time * 0.1;
      float veinLength = tileSize * 0.3 * (1 + sin(time + j) * 0.1);
      line(centerX, centerY,
           centerX + cos(angle) * veinLength,
           centerY + sin(angle) * veinLength);
    }
    
    popMatrix();
  }
}

void drawEnergyElements() {
  for (int i = 0; i < 3; i++) {
    float offset = energyOffset * (i + 1) * 0.5;
    float phase = time * (i + 1) * 0.5;

    stroke(energyColors[i]);
    strokeWeight(3 - i * 0.5);
    noFill();
    
    // Calculate size for energy elements inversely proportional to energy level
    float energyScale = map(energyLevel, minEnergy, maxEnergy, 0.5, 1.5); // Scale from 0.5 to 1.5

    // Main zigzag with curved corners
    beginShape();
    for (float t = 0; t <= 1; t += 0.1) {
      float x = t * tileSize * energyScale; // Scale the zigzag width
      float y = tileSize * (0.4 + i * 0.15) + 
                sin(t * PI * 2 + phase) * 20 + 
                offset;
      
      // Add small circular particles, size inversely related to energy level
      if (random(1) < 0.3) {
        fill(energyColors[i], 150);
        float particleSize = map(energyLevel, minEnergy, maxEnergy, 1, 5); // Particle size from 1 to 5
        circle(x, y, particleSize);
        noFill();
      }
      
      curveVertex(x, y);
    }
    endShape();
  }

  // Sparkle effects
  for (int i = 0; i < 5; i++) {
    float sparkX = random(tileSize);
    float sparkY = random(tileSize);
    float sparkSize = map(energyLevel, minEnergy, maxEnergy, 2, 6); // Sparkle size from 2 to 6
    float alpha = (sin(time * 3 + i) + 1) * 127;

    fill(energyColors[int(random(3))], alpha);
    noStroke();
    circle(sparkX, sparkY, sparkSize);
  }
}

// Key control for energy level (if needed)
void keyPressed() {
  if (keyCode == UP) {
    energyLevel = constrain(energyLevel + 5, minEnergy, maxEnergy);
  } else if (keyCode == DOWN) {
    energyLevel = constrain(energyLevel - 5, minEnergy, maxEnergy);
  }
  
  // Save the pattern if needed
  if (key == 's' || key == 'S') {
    save("tessellation.png");
  }
}