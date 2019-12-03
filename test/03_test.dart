import 'dart:io';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:test/test.dart';

enum Direction {
  right, left, up, down
}

class Move {

  final Direction direction;
  final int distance;

  Move(this.direction, this.distance);

  Move.parse(String s) : this(_parseDirection(s[0]), int.parse(s.substring(1)));

  static Direction _parseDirection(String s) {
    switch (s) {
      case "R": return Direction.right;
      case "L": return Direction.left;
      case "U": return Direction.up;
      case "D": return Direction.down;
      default: throw ArgumentError("Invalid direction: $s");
    }
  }
}

class Point extends Equatable {

  static const origin = Point(0, 0);

  final int x, y;

  const Point(this.x, this.y);

  @override
  List<Object> get props => [x, y];

  Point move(Direction direction) {
    switch (direction) {
      case Direction.right: return Point(x + 1, y);
      case Direction.left: return Point(x - 1, y);
      case Direction.up: return Point(x, y + 1);
      case Direction.down: return Point(x, y - 1);
      default: throw ArgumentError("Unsupported direction: $direction");
    }
  }
}

void main() {

  group("Day 3", () {

    List<Move> parseLine(String line) {
      return line.split(",").map((move) => Move.parse(move)).toList();
    }

    Set<Point> play(List<Move> moves) {
      var visited = Set<Point>();
      var current = Point.origin;
      for (var move in moves) {
        for (var i = 0; i < move.distance; ++i) {
          current = current.move(move.direction);
          visited.add(current);
        }
      }
      return visited;
    }

    int distanceToNearestCrossing(List<Move> first, List<Move> second) {
      return play(first).intersection(play(second))
        .map((point) => point.x.abs() + point.y.abs())
        .reduce(min);
    }

    test("distance to nearest crossing", () {
      expect(distanceToNearestCrossing(parseLine("R8,U5,L5,D3"), parseLine("U7,R6,D4,L4")), 6);
      expect(distanceToNearestCrossing(parseLine("R75,D30,R83,U83,L12,D49,R71,U7,L72"), parseLine("U62,R66,U55,R34,D71,R55,D58,R83")), 159);
      expect(distanceToNearestCrossing(parseLine("R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51"), parseLine("U98,R91,D20,R16,D67,R40,U7,R15,U6,R7")), 135);
    });

    List<List<Move>> input() {
      return File("data/03.txt")
        .readAsLinesSync()
        .map(parseLine)
        .toList();
    }

    test("Part 1", () {
      var wires = input();
      expect(distanceToNearestCrossing(wires[0], wires[1]), 386);
    });

    Map<Point, int> countSteps(List<Move> moves) {
      var visited = Map<Point, int>();
      var current = Point.origin;
      var steps = 0;
      for (var move in moves) {
        for (var i = 0; i < move.distance; ++i) {
          current = current.move(move.direction);
          ++steps;
          if (!visited.containsKey(current)) {
            visited[current] = steps;
          }
        }
      }
      return visited;
    }

    int stepsToNearestCrossing(List<Move> first, List<Move> second) {
      var firstSteps = countSteps(first);
      var secondSteps = countSteps(second);
      return Set.of(firstSteps.keys).intersection(Set.of(secondSteps.keys))
        .map((point) => firstSteps[point] + secondSteps[point])
        .reduce(min);
    }

    test("steps to nearest crossing", () {
      expect(stepsToNearestCrossing(parseLine("R8,U5,L5,D3"), parseLine("U7,R6,D4,L4")), 30);
      expect(stepsToNearestCrossing(parseLine("R75,D30,R83,U83,L12,D49,R71,U7,L72"), parseLine("U62,R66,U55,R34,D71,R55,D58,R83")), 610);
      expect(stepsToNearestCrossing(parseLine("R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51"), parseLine("U98,R91,D20,R16,D67,R40,U7,R15,U6,R7")), 410);
    });

    test("Part 2", () {
      var wires = input();
      expect(stepsToNearestCrossing(wires[0], wires[1]), 6484);
    });
  });
}
