int gridSizeX = 25;
int gridSizeY = 25;
int tileSize = 20;
int sidebarSizeX = 300;
int borderSize = 1;
int statusBarSize = 100;

TileType[][] world;
color groundColor = color(183, 72, 72);
color riverColor = color(44, 245, 240);
color stoneColor = color(198, 192, 192);
color textColor = color (255, 255, 255);
color ERROR_COLOR = color(252, 10, 252); 

Parent parent;
Child child;

Command walkLeft, walkRight, walkUp, walkDown, pickup, drop;

void setup()
{
  size(gridSizeX*tileSize+sidebarSizeX, gridSizeY*tileSize + statusBarSize);

  world = new TileType[gridSizeX][gridSizeY];
  for (int i = 0; i < gridSizeX; i++) {
    for (int j = 0; j < gridSizeY; j++) {
      world[i][j] = (random(1) < 0.1) ? TileType.RIVER : null;
    }
  }

  world = GenerateWorld(gridSizeX, gridSizeY, 3);



  int xPos, yPos;
  do {
    xPos = int(random(0, gridSizeX));
    yPos = int(random(0, gridSizeY));
  } 
  while (world[xPos][yPos] != null);
  parent = new Parent(xPos, yPos);

  do {
    xPos = int(random(parent.xPos - 5, parent.xPos + 5));
    yPos = int(random(parent.yPos - 5, parent.yPos + 5));
  } 
  while (!inBounds (xPos, yPos) || ((world[xPos][yPos] != null && xPos != parent.xPos && yPos != parent.yPos)));
  child = new Child(xPos, yPos);

  walkLeft = new WalkLeftCommand();
  walkRight = new WalkRightCommand();
  walkUp = new WalkUpCommand();
  walkDown = new WalkDownCommand();
  pickup = new PickupCommand();
  drop = new DropCommand();

  smooth();
}


void draw()
{
  background(0);

  //draw the base tile grid
  for (int i = 0; i < gridSizeX; i++) {
    for (int j = 0; j < gridSizeY; j++) {
      pushMatrix();
      translate(i*tileSize, j*tileSize);
      noStroke();
      if (world[i][j] == TileType.RIVER) {
        fill(riverColor);
      } else if (world[i][j] == TileType.STONE) {
        fill(stoneColor);
      } else {
        fill(groundColor);
      }
      rect(borderSize, borderSize, tileSize - 2*borderSize, tileSize - 2*borderSize);
      popMatrix();
    }
  }

  //draw the status bar
  fill(255);
  String holdingString = "Holding: ";
  holdingString += (parent.inventory != null && parent.inventory == TileType.STONE) ? "a stone!" : "nothing";
  text(holdingString, 10, gridSizeY*tileSize + 10);

  parent.render();
  child.render();

  // draw the current set of rules
  List<Rule> childRules = child.gitRules ();
  //List<Rule> childRules = testRules;
  println (childRules.size ());
  final int xOffset = gridSizeX * tileSize + tileSize;
  final int yOffset = 0;
  int line = 1;
  final int linewidth = 30;
  textFont(createFont("Arial", 14, true));
  fill (textColor);
  for (Rule rule : childRules) {
    String text = line+" "+rule.toString();  
    text(text, xOffset, yOffset+line*linewidth);  
    println (text);
    line++;
  }
}

void keyPressed()
{
  Event event = new Event();

  //what is true about the world before the action takes place?
  ArrayList<Condition> conditions = checkConditions(parent);
  event.addPreconditions(conditions);

  Action occurredAction = null;
  if (keyCode == LEFT) occurredAction = walkLeft.perform(parent);
  else if (keyCode == RIGHT) occurredAction = walkRight.perform(parent);
  else if (keyCode == UP) occurredAction = walkUp.perform(parent);
  else if (keyCode == DOWN) occurredAction = walkDown.perform(parent);
  else if (key == 'p') occurredAction = pickup.perform(parent);
  else if (key == 'd') occurredAction = drop.perform(parent);
  // now, the numbers that refer to rules
  else if (key > '1' && key < '9') removeRuleRequest (key - '0');

  //add the action to the event
  if (occurredAction != null) {
    event.addAction(occurredAction);
  }

  //todo: event is constructed at this point, but where do I send it??
  println(event);
  child.addEventToMemory(event);

  ArrayList<Condition> childConditions = checkConditions(child);
  //execute the next command in the child's queue
  child.executeNextCommand(childConditions);
  child.learn();
}

void removeRuleRequest (int which) {
  // more logic here to use resources etc
  child.removeRuleFromMemory (child.gitRules().get(which));
}

