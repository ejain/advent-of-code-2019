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

    test("find targets", () {
      final grid = Grid.parse("""
        .#..#
        .....
        #####
        ....#
        ...##
      """);
      expect(grid.findTargets(Point(1, 0)), hasLength(7));
      expect(grid.findTargets(Point(4, 0)), hasLength(7));
      expect(grid.findTargets(Point(0, 2)), hasLength(6));
      expect(grid.findTargets(Point(1, 2)), hasLength(7));
      expect(grid.findTargets(Point(2, 2)), hasLength(7));
      expect(grid.findTargets(Point(3, 2)), hasLength(7));
      expect(grid.findTargets(Point(4, 2)), hasLength(5));
      expect(grid.findTargets(Point(4, 3)), hasLength(7));
      expect(grid.findTargets(Point(3, 4)), hasLength(8));
      expect(grid.findTargets(Point(4, 4)), hasLength(7));
      expect(grid.findCenter(), Point(3, 4));
    });

    String input() => File("data/10.txt").readAsStringSync();

    test("Part 1", () {
      final grid = Grid.parse(input());
      final best = grid.findCenter();
      expect(grid.findTargets(best), hasLength(274));
      expect(best, Point(19, 14));
    });

    test("directions", () {
      expect(Point(0, -1).direction(), 0);
      expect(Point(1, -1).direction(), 45);
      expect(Point(1, 0).direction(), 90);
      expect(Point(1, 1).direction(), 135);
      expect(Point(0, 1).direction(), 180);
      expect(Point(-1, 1).direction(), 225);
      expect(Point(-1, 0).direction(), 270);
      expect(Point(-1, -1).direction(), 315);
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
        final targets = grid.findTargets(center);
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

    test("vaporize, large example", () {
      final grid = Grid.parse("""
        .#..##.###...#######
        ##.############..##.
        .#.######.########.#
        .###.#######.####.#.
        #####.##.#.##.###.##
        ..#####..#.#########
        ####################
        #.####....###.#.#.##
        ##.#################
        #####.##.###..####..
        ..######..##.#######
        ####.##.####...##..#
        .#####..#.######.###
        ##...#.##########...
        #.##########.#######
        .####.#.###.###.#.##
        ....##.##.###..#####
        .#.#.###########.###
        #.#.#.#####.####.###
        ###.##.####.##.#..##
      """);
      final vaporized = vaporize(grid, Point(11, 13), 300);
      expect(vaporized, hasLength(299));
      expect(vaporized.first, Point(11, 12));
      expect(vaporized.last, Point(11, 1));
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

  bool contains(Point point) => point.x >= 0 && point.x < _width && point.y >= 0 && point.y < _height;

  List<Point> findTargets(Point source) {
    final nearestTargets = SplayTreeMap<double, Point>();
    for (Point target in _iterator().where((point) => !isEmpty(point))) {
      if (target != source) {
        final delta = source.delta(target);
        final nearest = nearestTargets[delta.direction()];
        if (nearest == null || delta.length() < source.delta(nearest).length()) {
          nearestTargets[delta.direction()] = target;
        }
      }
    }
    return nearestTargets.values.toList();
  }

  Point findCenter() {
    Point center;
    var maxCount = 0;
    for (var point in _iterator().where((point) => !isEmpty(point))) {
      var count = findTargets(point).length;
      if (point == null || count > maxCount) {
        center = point;
        maxCount = count;
      }
    }
    return center;
  }

  Iterable<Point> _iterator() sync* {
    for (var x = 0; x < _width; ++x) {
      for (var y = 0; y < _height; ++y) {
        yield Point(x, y);
      }
    }
  }
}

class Position {

  static const empty = Position._(".");
  static const asteroid = Position._("#");

  final String _symbol;

  const Position._(this._symbol);

  static Position parse(String s) {
    switch (s) {
      case ".": return empty;
      case "#": return asteroid;
      default: throw ArgumentError("invalid position: $s");
    }
  }

  @override
  String toString() => _symbol;
}

class Point extends Equatable {

  final int x, y;

  const Point(this.x, this.y);

  Point add(Point delta) => Point(x + delta.x, y + delta.y);

  double direction() {
    var value = (180 * atan2(x, -y) / pi);
    if (value < 0) {
      value += 360;
    }
    return value;
  }

  double length() => sqrt(pow(x, 2) + pow(y, 2));

  Point delta(Point point) => Point(point.x - x, point.y - y);

  @override
  List<Object> get props => [x, y];

  @override
  String toString() => "($x, $y)";
}
