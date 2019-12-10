import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:quiver/check.dart';
import 'package:test/test.dart';

void main() {

  group("Day 10", () {

    test("parse a grid", () {
      final grid = Grid.parse("""
        #..
        .#.
      """);
      expect(grid.isEmpty(Point(0, 0)), isFalse, reason: "(0, 0)");
      expect(grid.isEmpty(Point(2, 0)), isTrue, reason: "(2, 0)");
      expect(grid.isEmpty(Point(0, 1)), isTrue, reason: "(0, 1)");
      expect(grid.isEmpty(Point(2, 1)), isTrue, reason: "(2, 1)");
      expect(() => grid.isEmpty(Point(3, 0)), throwsArgumentError, reason: "(3, 0)");
      expect(() => grid.isEmpty(Point(0, 2)), throwsArgumentError, reason: "(0, 2)");
    });

    test("get sight lines (3x3)", () {
      final grid = Grid.parse("""
        ###
        ###
        ###
      """);
      final actual = grid.getSightLines(Point(1, 1)).toList();
      expect(actual, [
        [Point(1, 0)],
        [Point(2, 0)],
        [Point(2, 1)],
        [Point(2, 2)],
        [Point(1, 2)],
        [Point(0, 2)],
        [Point(0, 1)],
        [Point(0, 0)],
      ]);
    });

    test("get sight lines (5x5)", () {
      final grid = Grid.parse("""
        #####
        #####
        #####
        #####
        #####
      """);
      final actual = grid.getSightLines(Point(2, 2));
      expect(actual, allOf(hasLength(16), containsAll([
        [Point(2, 1), Point(2, 0)],
        [Point(0, 3)],
        [Point(3, 1), Point(4, 0)],
        [Point(4, 1)],
        [Point(3, 2), Point(4, 2)],
      ])));
    });

    test("find visible points", () {
      final grid = Grid.parse("""
        .#..#
        .....
        #####
        ....#
        ...##
      """);
      expect(grid.findVisible(Point(1, 0)), hasLength(7));
      expect(grid.findVisible(Point(4, 0)), hasLength(7));
      expect(grid.findVisible(Point(0, 2)), hasLength(6));
      expect(grid.findVisible(Point(1, 2)), hasLength(7));
      expect(grid.findVisible(Point(2, 2)), hasLength(7));
      expect(grid.findVisible(Point(3, 2)), hasLength(7));
      expect(grid.findVisible(Point(4, 2)), hasLength(5));
      expect(grid.findVisible(Point(4, 3)), hasLength(7));
      expect(grid.findVisible(Point(3, 4)), hasLength(8));
      expect(grid.findVisible(Point(4, 4)), hasLength(7));
      expect(grid.findCenter(), Point(3, 4));
    });

    String input() => File("data/10.txt").readAsStringSync();

    test("Part 1", () {
      final grid = Grid.parse(input());
      final best = grid.findCenter();
      expect(grid.findVisible(best), hasLength(274));
      expect(best, Point(19, 14));
    });

    test("convert point to degrees", () {
      expect(Point(0, -1).toDegrees(), 0);
      expect(Point(1, -1).toDegrees(), 45);
      expect(Point(1, 0).toDegrees(), 90);
      expect(Point(1, 1).toDegrees(), 135);
      expect(Point(0, 1).toDegrees(), 180);
      expect(Point(-1, 1).toDegrees(), 225);
      expect(Point(-1, 0).toDegrees(), 270);
      expect(Point(-1, -1).toDegrees(), 315);
    });

    test("clear a point", () {
      final grid = Grid.parse("""
        ...
        .#.
        ...
      """);
      final target = Point(1, 1);
      expect(grid.isEmpty(target), isFalse);
      grid.clear(target);
      expect(grid.isEmpty(target), isTrue);
    });

    List<Point> vaporize(Grid grid, Point center, int shots) {
      var vaporized = <Point>[];
      while (shots > 0) {
        final targets = grid.findVisible(center);
        if (targets.isEmpty) {
          break;
        }
        for (var target in targets) {
          grid.clear(target);
          vaporized.add(target);
          if (--shots == 0) {
            break;
          }
        }
      }
      return vaporized;
    }

    test("vaporize", () {
      final grid = Grid.parse("""
        .#....#####...#..
        ##...##.#####..##
        ##...#...#.#####.
        ..#.....#...###..
        ..#.#.....#....##      
      """);
      final vaporized = vaporize(grid, Point(8, 3), 100);
      expect(vaporized, hasLength(36));
      expect(vaporized.last, Point(14, 3));
    });

    test("Part 2", () {
      final grid = Grid.parse(input());
      final vaporized = vaporize(grid, Point(19, 14), 200);
      expect(vaporized, hasLength(200));
      expect(vaporized.last, Point(3, 5));
    });
  });
}

class Grid {

  final int _width, _height;
  final List<Position> _positions;

  Grid._(this._width, this._height, this._positions);

  static Grid parse(String s) {
    final lines = s.trim().split("\n").map((line) => line.trim()).toList();
    final positions = lines.expand((line) => line.split("")).map(Position.parse).toList();
    return Grid._(lines[0].length, lines.length, positions);
  }

  bool isEmpty(Point point) => _positions[_offset(point)] == Position.empty;

  void clear(Point point) => _positions[_offset(point)] = Position.empty;

  int _offset(Point point) {
    checkArgument(contains(point), message: "invalid point: ${point}");
    return point.x + point.y * _width;
  }

  bool contains(Point point) => point.x >= 0 &&point.x < _width && point.y >= 0 && point.y < _height;

  List<List<Point>> getSightLines(Point source) {
    checkArgument(contains(source), message: "invalid point: $source");
    final sightLines = SplayTreeMap<Point, List<Point>>((a, b) => a.toDegrees().compareTo(b.toDegrees()));
    final seen = {source};
    for (var delta in _deltas(source)) {
      final steps = <Point>[];
      for (var step = source; contains(step); step = step.add(delta)) {
        if (seen.add(step)) {
          steps.add(step);
        }
      }
      if (steps.isNotEmpty) {
        sightLines[delta] = steps;
      }
    }
    return sightLines.values.toList();
  }

  Iterable<Point> _deltas(Point from) sync* {
    for (var dx in _iterate(from.x, _width)) {
      for (var dy in _iterate(from.y, _height)) {
        if (dy != 0 || dx != 0) {
          yield Point(dx, dy);
        }
      }
    }
  }

  Iterable<int> _iterate(int from, int limit) sync* {
    for (var i = 0; i < limit - from; ++i) {
      yield i;
    }
    for (var i = 0; i >= -from; --i) {
      yield i;
    }
  }

  Set<Point> findVisible(Point source) {
    final visible = Set<Point>();
    for (var sightLine in getSightLines(source)) {
      for (var target in sightLine) {
        if (!isEmpty(target)) {
          visible.add(target);
          break;
        }
      }
    }
    return visible;
  }

  Point findCenter() {
    Point center;
    var maxCount = 0;
    for (var point in _iterator().where((point) => !isEmpty(point))) {
      var count = findVisible(point).length;
      if (point == null || count > maxCount) {
        center = point;
        maxCount = count;
      }
    }
    return center;
  }

  Iterable<Point> _iterator() sync* {
    for (var x = 0; x < _width; ++x) {
      for (var y = 0; y < _width; ++y) {
        yield Point(x, y);
      }
    }
  }
}

class Position {

  static const empty = Position(".");
  static const asteroid = Position("#");

  final String _symbol;

  const Position(this._symbol);

  static Position parse(String s) {
    switch (s) {
      case ".": return empty;
      case "#": return Position.asteroid;
      default: throw ArgumentError("invalid position: $s");
    }
  }
}

class Point extends Equatable {

  final int x, y;

  const Point(this.x, this.y);

  Point add(Point delta) => Point(x + delta.x, y + delta.y);

  double toDegrees() {
    var value = (180 * atan2(x, -y) / pi);
    if (value < 0) {
      value += 360;
    }
    return value;
  }

  @override
  List<Object> get props => [x, y];

  @override
  String toString() => "($x, $y)";
}
