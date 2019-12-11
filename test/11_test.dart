import 'dart:io';
import 'dart:math';

import 'package:advent_of_code/intcode.dart';
import 'package:equatable/equatable.dart';
import 'package:test/test.dart';

void main() {

  group("Day 11", () {

    test("move left", () {
      final robot = Robot(Hull());
      expect(robot.panel, Point(0, 0));
      expect(robot.heading, Heading.up);

      robot.move(Turn.left);
      expect(robot.panel, Point(-1, 0));
      expect(robot.heading, Heading.left);

      robot.move(Turn.left);
      expect(robot.panel, Point(-1, 1));
      expect(robot.heading, Heading.down);

      robot.move(Turn.left);
      expect(robot.panel, Point(0, 1));
      expect(robot.heading, Heading.right);

      robot.move(Turn.left);
      expect(robot.panel, Point(0, 0));
      expect(robot.heading, Heading.up);
    });

    test("move right", () {
      final robot = Robot(Hull());
      expect(robot.panel, Point(0, 0));
      expect(robot.heading, Heading.up);

      robot.move(Turn.right);
      expect(robot.panel, Point(1, 0));
      expect(robot.heading, Heading.right);

      robot.move(Turn.right);
      expect(robot.panel, Point(1, 1));
      expect(robot.heading, Heading.down);

      robot.move(Turn.right);
      expect(robot.panel, Point(0, 1));
      expect(robot.heading, Heading.left);

      robot.move(Turn.right);
      expect(robot.panel, Point(0, 0));
      expect(robot.heading, Heading.up);
    });

    test("paint", () {
      final hull = Hull();
      final robot = Robot(hull);
      expect(hull.getColor(robot.panel), Color.black);
      expect(hull.numPainted(), 0);

      robot.paint(Color.white);
      expect(hull.getColor(robot.panel), Color.white);
      expect(hull.numPainted(), 1);

      robot.paint(Color.black);
      expect(hull.getColor(robot.panel), Color.black);
      expect(hull.numPainted(), 1);
    });

    List<int> input() => File("data/11.txt")
      .readAsStringSync()
      .split(",")
      .map(int.parse)
      .toList();

    void paint(Hull hull) {
      final robot = Robot(hull);
      final intcode = Intcode(input(), []);
      do {
        final color = intcode.runStep(hull.getColor(robot.panel).index);
        if (color != null) {
          robot.paint(Color.values[color]);
        }
        final turn = intcode.runStep();
        if (turn != null) {
          robot.move(Turn.values[turn]);
        }
      } while (!intcode.isTerminated);
    }

    test("Part 1", () {
      final hull = Hull();
      paint(hull);
      expect(hull.numPainted(), 2594);
    });

    test("Part 2", () {
      final hull = Hull();
      hull.paint(Point(0, 0), Color.white);
      paint(hull);
      expect(hull.toString(),
        "██  ██ ██ █    █   ████  █    █ ██ █ ██ ███\n"
        "█ ██ █ █ ██ ████ ██ ████ █ ████ ██ █ █ ████\n"
        "█ ██ █  ███   ██ ██ ████ █   ██    █  █████\n"
        "█    █ █ ██ ████   █████ █ ████ ██ █ █ ████\n"
        "█ ██ █ █ ██ ████ █ ██ ██ █ ████ ██ █ █ ████\n"
        "█ ██ █ ██ █    █ ██ ██  ██ ████ ██ █ ██ ███\n"
      );
    });
  });
}

enum Turn { left, right }

enum Heading { up, right, down, left }

extension on Heading {

  Heading turn(Turn turn) {
    return Heading.values[(index + (turn.index * 2 - 1)) % Heading.values.length];
  }

  Point get delta {
    switch (this) {
      case Heading.up: return const Point(0, -1);
      case Heading.down: return const Point(0, 1);
      case Heading.left: return const Point(-1, 0);
      case Heading.right: return const Point(1, 0);
    }
    return null;
  }
}

enum Color { black, white }

class Point extends Equatable {

  final int x, y;

  const Point(this.x, this.y);

  Point add(Point delta) => Point(x + delta.x, y + delta.y);

  @override
  List<Object> get props => [x, y];

  @override
  String toString() => "($x, $y)";
}

class Robot {

  var _panel = Point(0, 0);
  var _heading = Heading.up;
  final Hull _hull;

  Robot(this._hull);

  Point get panel => _panel;

  Heading get heading => _heading;

  void paint(Color color) => _hull.paint(_panel, color);

  void move(Turn turn) {
    _heading = _heading.turn(turn);
    _panel = _panel.add(_heading.delta);
  }
}

class Hull {

  final _painted = <Point, Color>{};

  void paint(Point panel, Color color) => _painted[panel] = color;

  Color getColor(Point panel) => _painted[panel] ?? Color.black;

  int numPainted() => _painted.length;

  Point _topLeft() => Point(
    _painted.keys.map((point) => point.x).reduce(min),
    _painted.keys.map((point) => point.y).reduce(min)
  );

  Point _bottomRight() => Point(
    _painted.keys.map((point) => point.x).reduce(max),
    _painted.keys.map((point) => point.y).reduce(max)
  );

  @override
  String toString() {
    final buffer = StringBuffer();
    final topLeft = _topLeft();
    final bottomRight = _bottomRight();
    for (var y = topLeft.y; y <= bottomRight.y; ++y) {
      for (var x = topLeft.x; x <= bottomRight.x; ++x) {
        buffer.write(getColor(Point(x, y)) == Color.white ? " " : "█");
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
