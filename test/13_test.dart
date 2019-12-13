import 'dart:io';
import 'dart:math';

import 'package:advent_of_code/intcode.dart';
import 'package:equatable/equatable.dart';
import 'package:quiver/check.dart';
import 'package:test/test.dart';

void main() {

  group("Day 13", () {

    test("draw tiles", () {

      final screen = Screen();
      expect(screen.blocks, 0);
      expect(screen.ball, isNull);
      expect(screen.paddle, isNull);

      screen.draw(Point(0, 0), Tile.ball);
      screen.draw(Point(1, 0), Tile.paddle);
      screen.draw(Point(2, 0), Tile.block);
      screen.draw(Point(2, 1), Tile.block);

      expect(screen.blocks, 2);
      expect(screen.ball, Point(0, 0));
      expect(screen.paddle, Point(1, 0));
    });

    List<int> input() => File("data/13.txt")
      .readAsStringSync()
      .split(",")
      .map(int.parse)
      .toList();

    test("Part 1", () {
      final arcade = Arcade(input());
      arcade.start();
      expect(arcade.screen.blocks, 306);
    });

    test("Part 2", () {
      final codes = input();
      codes[0] = 2;
      final arcade = Arcade(codes);
      arcade.start();
      expect(Player().play(arcade), 15328);
    });
  });
}

enum Tile { empty, wall, block, paddle, ball }

class Point extends Equatable {

  final int x, y;

  const Point(this.x, this.y);

  @override
  List<Object> get props => [x, y];

  @override
  String toString() => "($x, $y)";
}

class Screen {

  final _tiles = <Point, Tile>{};
  Point _ball, _paddle;

  void draw(Point point, Tile tile) {
    if (tile == Tile.ball) {
      _ball = point;
    } else if (tile == Tile.paddle) {
      _paddle = point;
    }
    _tiles[point] = tile;
  }

  int get blocks => _tiles.values.where((tile) => tile == Tile.block).length;

  Point get ball => _ball;

  Point get paddle => _paddle;

  Point _topLeft() => Point(
      _tiles.keys.map((point) => point.x).reduce(min),
      _tiles.keys.map((point) => point.y).reduce(min)
  );

  Point _bottomRight() => Point(
      _tiles.keys.map((point) => point.x).reduce(max),
      _tiles.keys.map((point) => point.y).reduce(max)
  );

  @override
  String toString() {
    final buffer = StringBuffer();
    final topLeft = _topLeft();
    final bottomRight = _bottomRight();
    for (var y = topLeft.y; y <= bottomRight.y; ++y) {
      for (var x = topLeft.x; x <= bottomRight.x; ++x) {
        buffer.write(_toChar(_tiles[Point(x, y)] ?? Tile.empty));
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  static String _toChar(Tile tile) {
    switch (tile) {
      case Tile.wall: return "|";
      case Tile.block: return "x";
      case Tile.paddle: return "@";
      case Tile.ball: return "o";
      default: return " ";
    }
  }
}

class Arcade {

  final Intcode _intcode;
  final _screen = Screen();
  int _score = 0;

  Arcade(List<int> codes) : _intcode = Intcode(codes, []);

  Screen get screen => _screen;

  int get score => _score;

  void start() {
    try {
      _intcode.run();
    } on MissingInputException {
    } finally {
      _process(_intcode.drain().reversed.toList());
    }
  }

  bool input(Position position) {
    _intcode.addInput(position.inputCode);
    try {
      _process(_intcode.run().reversed.toList());
      return false;
    } on MissingInputException {
      _process(_intcode.drain().reversed.toList());
      return true;
    }
  }

  void _process(List<int> output) {
    checkState(output.length % 3 == 0, message: "expected triples");
    while (output.isNotEmpty) {
      final x = output.removeLast();
      final y = output.removeLast();
      final z = output.removeLast();
      if (x == -1 && y == 0) {
        _score = z;
      } else {
        _screen.draw(Point(x, y), Tile.values[z]);
      }
    }
  }
}

enum Position { left, neutral, right }

extension PositionInputCode on Position {

  int get inputCode => index - 1;
}

class Player {

  int play(Arcade arcade) {
    while (arcade.screen.blocks > 0) {
      if (!arcade.input(_next(arcade.screen))) {
        break;
      }
    }
    checkState(arcade.screen.blocks == 0, message: "game over");
    return arcade.score;
  }

  Position _next(Screen screen) {
    if (screen.paddle.x > screen.ball.x) {
      return Position.left;
    }
    if (screen.paddle.x < screen.ball.x) {
      return Position.right;
    }
    return Position.neutral;
  }
}
