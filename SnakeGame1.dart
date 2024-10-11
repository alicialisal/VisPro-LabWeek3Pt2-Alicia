import 'dart:async';
import 'dart:io';
import 'dart:math';

class Point {
  int x, y;
  Point(this.x, this.y);
}

class SnakePart {
  Point position;
  List<String> symbol;
  SnakePart(this.position, this.symbol);
}

class Snake {
  List<SnakePart> body = [];
  String direction = 'down';

  Snake(int x, int y) {
    body.add(SnakePart(Point(x, y), ['  *  ', '*****', '  *  ', '*****', '  *  ']));
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
        newHead = Point(body.first.position.x, body.first.position.y + 1);
    }

    // Shift body parts
    for (int i = body.length - 1; i > 0; i--) {
      body[i].position = body[i - 1].position;
    }
    body.first.position = newHead;
  }

  void grow() {
  // Hitung posisi tengah untuk menyisipkan segmen baru
  int middleIndex = (body.length / 2).floor();

  // Tambahkan segmen baru di tengah
  body.insert(middleIndex, SnakePart(body[middleIndex].position, ['  *  ', '*****', '  *  ', '*****', '  *  ']));
  }



  void decideDirection(Point food) {
    Point head = body.first.position;

    // Determine the direction towards the food
    if (head.y < food.y) {
      direction = 'down';
    } else if (head.y > food.y) {
      direction = 'up';
    } else if (head.x < food.x) {
      direction = 'right';
    } else if (head.x > food.x) {
      direction = 'left';
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
    snake = Snake(width ~/ 2, 0);
    _generateFood();
  }

  void _initializeSize() {
    if (stdout.hasTerminal) {
      width = stdout.terminalColumns - 2;
      height = stdout.terminalLines - 3;
    } else {
      width = 50;
      height = 25;
    }
  }

  void _generateFood() {
    Random random = Random();
    do {
      food = Point(random.nextInt(width), random.nextInt(height));
    } while (snake.body.any((part) => 
      part.position.x <= food.x && food.x < part.position.x + 7 &&
      part.position.y <= food.y && food.y < part.position.y + 5
    ));
  }

  void update() {
    if (!gameOver) {
      snake.decideDirection(food); // Update direction towards food
      snake.move();

      if (snake.body.first.position.x <= food.x && food.x < snake.body.first.position.x + 7 &&
          snake.body.first.position.y <= food.y && food.y < snake.body.first.position.y + 5) {
        snake.grow();
        _generateFood();
      }

      if (snake.body.first.position.x < 0 || snake.body.first.position.x + 7 > width ||
          snake.body.first.position.y < 0 || snake.body.first.position.y + 5 > height) {
        gameOver = true;
      }

      for (int i = 1; i < snake.body.length; i++) {
        if (snake.body.first.position.x == snake.body[i].position.x && 
            snake.body.first.position.y == snake.body[i].position.y) {
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
      print('\n' * 50);
    }

    List<List<String>> grid = List.generate(height, (_) => List.filled(width, ' '));

    // Place snake on grid
    for (var part in snake.body) {
      for (int i = 0; i < part.symbol.length; i++) {
        if (part.position.y + i >= 0 && part.position.y + i < height) {
          for (int j = 0; j < part.symbol[i].length; j++) {
            if (part.position.x + j >= 0 && part.position.x + j < width) {
              grid[part.position.y + i][part.position.x + j] = part.symbol[i][j];
            }
          }
        }
      }
    }

    // Place food on grid
    if (food.y >= 0 && food.y < height && food.x >= 0 && food.x < width) {
      grid[food.y][food.x] = '@';
    }

    // Render grid
    for (var row in grid) {
      print(row.join());
    }

    print('Score: ${snake.body.length - 1}');

    if (gameOver) {
      print('Game Over! Your final score: ${snake.body.length - 1}');
    }

    
  }
}

void main() async {
  Game game = Game();
  game.render();

  await Future.delayed(Duration(seconds: 2));

  // Create a timer for the game loop
  Timer.periodic(Duration(milliseconds: 200), (timer) {
    game.update();
    game.render();

    if (game.gameOver) {
      timer.cancel();
      exit(0);
    }
  });
}
