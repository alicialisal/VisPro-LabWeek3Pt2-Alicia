import 'dart:async';
import 'dart:io';
import 'dart:math';

class Point {
  int x, y;
  Point(this.x, this.y);
}

class SnakePart {
  Point position;
  String symbol;
  String part;
  SnakePart(this.position, this.symbol, this.part);
}

class Snake {
  List<SnakePart> body = [];
  String direction = 'right';

  Snake(int x, int y) {
    body.add(SnakePart(Point(x, y), '*', 'head'));     // Head
    body.add(SnakePart(Point(x - 1, y), '*****', 'frontleg')); // Front legs
    body.add(SnakePart(Point(x - 2, y), '*', 'body')); // Body
    body.add(SnakePart(Point(x - 3, y), '*****', 'backleg')); // Back legs
    body.add(SnakePart(Point(x - 4, y), '*', 'tail')); // Tail
  }

  void move() {
    Point newHead;
    switch (direction) {
      case 'up':
        newHead = Point(body.first.position.x, body.first.position.y - 1);
        break;
      case 'down':
        newHead = Point(body.first.position.x, body.first.position.y + 1);
        break;
      case 'left':
        newHead = Point(body.first.position.x - 1, body.first.position.y);
        break;
      case 'right':
        newHead = Point(body.first.position.x + 1, body.first.position.y);
        break;
      default:
        newHead = Point(body.first.position.x + 1, body.first.position.y);
    }

    for (int i = body.length - 1; i > 0; i--) {
      body[i].position = Point(body[i - 1].position.x, body[i - 1].position.y);
      
      if (direction == 'up' || direction == 'down') {
        if (i == 0 || (i < body.length - 2 && i > 1) || (i == body.length - 1)) { 
          body[i].symbol = '*'; 
        } else {
          body[i].symbol = '*****';  
        }
      } else {
          body[i].symbol = '*';  // Menggunakan simbol tunggal untuk kaki
      }
    }
    
    body[0].position = newHead;
    body[0].symbol = (direction == 'up' || direction == 'down') ? '*' : '*';
  }

  void grow() {
    // Insert new body segment after the front legs
    body.insert(2, SnakePart(Point(body[1].position.x, body[1].position.y), '*', 'body'));
  }

  void decideDirection(Point food) {
    Point head = body.first.position;
    if (head.x < food.x) {
      direction = 'right';
    } else if (head.x > food.x) {
      direction = 'left';
    } else if (head.y < food.y) {
      direction = 'down';
    } else if (head.y > food.y) {
      direction = 'up';
    }
  }
}

class Game {
  late int width;
  late int height;
  late Snake snake;
  late Point food;
  bool gameOver = false;

  Game() {
    _initializeSize();
    snake = Snake(width ~/ 2, height ~/ 2);
    _generateFood();
  }

  void _initializeSize() {
    if (stdout.hasTerminal) {
      width = stdout.terminalColumns - 2; // Leave some margin
      height = stdout.terminalLines - 3; // Leave some space for messages
    } else {
      width = 30;
      height = 15;
    }
  }

  void _generateFood() {
    Random random = Random();
    do {
      food = Point(random.nextInt(width - 5), random.nextInt(height - 5));
    } while (snake.body.any((part) => part.position.x == food.x && part.position.y == food.y));
  }

  bool isOutOfBounds(Point point) {
    return point.x < 0 || point.x >= width || point.y < 0 || point.y >= height;
  }

  void update() {
    if (!gameOver) {
      snake.decideDirection(food);
      snake.move();

      if (snake.body.first.position.x == food.x && snake.body.first.position.y == food.y) {
        snake.grow();
        _generateFood();
      }

      if (snake.body.first.position.x < 0 || snake.body.first.position.x >= width - 2 ||
          snake.body.first.position.y < 0 || snake.body.first.position.y >= height - 2) {
        gameOver = true;
      }

      for (int i = 1; i < snake.body.length; i++) {
        if (snake.body[i].position.x == snake.body.first.position.x && 
            snake.body[i].position.y == snake.body.first.position.y) {
          gameOver = true;
          break;
        }
      }
    }
  }

  void render() {
    if (stdout.hasTerminal) {
      stdout.write('\x1B[2J\x1B[0;0H');
    } else {
      print('\n' * 50);  // Clear screen for non-terminal environments
    }

    List<List<String>> grid = List.generate(height, (_) => List.filled(width, ' '));

    // Place snake on grid
    for (var part in snake.body) {
      if (part.part == 'frontleg' || part.part == 'backleg') {
        // For legs, place vertically or horizontally
        if (snake.direction == 'up' || snake.direction == 'down') {
          for (int i = -2; i <= 2; i++) {
            int x = part.position.x + i;
            if (x >= 0 && x < width && part.position.y >= 0 && part.position.y < height) {
              grid[part.position.y][x] = '*';
            }
          }
        } else {
          for (int i = -2; i <= 2; i++) {
            int y = part.position.y + i;
            if (part.position.x >= 0 && part.position.x < width && y >= 0 && y < height) {
              grid[y][part.position.x] = '*';
            }
          }
        }
      } else if (part.position.x >= 0 && part.position.x < width &&
                 part.position.y >= 0 && part.position.y < height) {
        grid[part.position.y][part.position.x] = part.symbol;
      }
    }

    // Place food on grid
    if (!isOutOfBounds(food)) {
      grid[food.y][food.x] = '@';
    }

    // Render grid
    for (var row in grid) {
      print(row.join());
    }

    print('Score: ${snake.body.length - 5}');  // Subtract initial length

    if (gameOver) {
      print('Game Over! Your snake length: ${snake.body.length}');
    }
  }
}
void main() async {
  Game game = Game();

  Timer.periodic(Duration(milliseconds: 300), (timer) {
    game.update();
    game.render();

    if (game.gameOver) {
      timer.cancel();
      exit(0);
    }
  });
}
