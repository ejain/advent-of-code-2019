import 'dart:io';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:quiver/check.dart';
import 'package:quiver/iterables.dart' as iterables;
import 'package:quiver/strings.dart';
import 'package:test/test.dart';

void main() {

  group("Day 20", () {

    test("parse maze", () {
      final maze = Maze.parse("""
                 A
                 A
          #######.#########
          #######.........#
          #######.#######.#
          #######.#######.#
          #######.#######.#
          #####  B    ###.#
        BC...##  C    ###.#
          ##.##       ###.#
          ##...DE  F  ###.#
          #####    G  ###.#
          #########.#####.#
        DE..#######...###.#
          #.#########.###.#
        FG..#########.....#
          ###########.#####
                     Z
                     Z
      """, trim: 8);
      expect(maze.dimensions, Point(19, 19));

      expect(maze.start, Point(9, 2));
      expect(maze.teleport(Point(9, 2)), isNull);

      expect(maze.end, Point(13, 16));
      expect(maze.teleport(Point(13, 16)), isNull);

      expect(maze.teleport(Point(2, 13)), Point(6, 10), reason: "DE");
      expect(maze.teleport(Point(6, 10)), Point(2, 13), reason: "DE");

      expect(maze.teleport(Point(11, 12)), Point(2, 15), reason: "FG");
      expect(maze.teleport(Point(2, 15)), Point(11, 12), reason: "FG");

      expect(maze.solve(), 23);
    });

    test("parse multilevel maze", () {
      final maze = Maze.parse("""
                     Z L X W       C                 
                     Z P Q B       K                 
          ###########.#.#.#.#######.###############  
          #...#.......#.#.......#.#.......#.#.#...#  
          ###.#.#.#.#.#.#.#.###.#.#.#######.#.#.###  
          #.#...#.#.#...#.#.#...#...#...#.#.......#  
          #.###.#######.###.###.#.###.###.#.#######  
          #...#.......#.#...#...#.............#...#  
          #.#########.#######.#.#######.#######.###  
          #...#.#    F       R I       Z    #.#.#.#  
          #.###.#    D       E C       H    #.#.#.#  
          #.#...#                           #...#.#  
          #.###.#                           #.###.#  
          #.#....OA                       WB..#.#..ZH
          #.###.#                           #.#.#.#  
        CJ......#                           #.....#  
          #######                           #######  
          #.#....CK                         #......IC
          #.###.#                           #.###.#  
          #.....#                           #...#.#  
          ###.###                           #.#.#.#  
        XF....#.#                         RF..#.#.#  
          #####.#                           #######  
          #......CJ                       NM..#...#  
          ###.#.#                           #.###.#  
        RE....#.#                           #......RF
          ###.###        X   X       L      #.#.#.#  
          #.....#        F   Q       P      #.#.#.#  
          ###.###########.###.#######.#########.###  
          #.....#...#.....#.......#...#.....#.#...#  
          #####.#.###.#######.#######.###.###.#.#.#  
          #.......#.......#.#.#.#.#...#...#...#.#.#  
          #####.###.#####.#.#.#.#.###.###.#.###.###  
          #.......#.....#.#...#...............#...#  
          #############.#.#.###.###################  
                       A O F   N                     
                       A A D   M                     
      """, trim: 8, multilevel: true) as MultiMaze;

      expect(maze.dimensions, Point(45, 37));
      expect(maze.start, Point(15, 34));
      expect(maze.end, Point(13, 2));

      expect(maze.multiteleport(Path(Point(13, 8), 0, 0)), Path(Point(19, 34), 1, 1), reason: "teleport in");
      expect(maze.multiteleport(Path(Point(19, 34), 1, 1)), Path(Point(13, 8), 2, 0), reason: "teleport out");
      expect(maze.multiteleport(Path(Point(19, 34), 2, 0)), isNull, reason: "can't teleport out of main level");

      expect(maze.solve(), 396);
    });

    final input = File("data/20.txt").readAsStringSync();

    test("Part 1", () {
      final maze = Maze.parse(input);
      expect(maze.dimensions, isNotNull);
      expect(maze.solve(), 594);
    });

    test("Part 2", () {
      final maze = Maze.parse(input, multilevel: true);
      expect(maze.dimensions, isNotNull);
      expect(maze.solve(), 6812);
    });
  });
}

class Maze {

  final Point dimensions;
  final Map<Point, String> _tiles;
  final Map<Point, Portal> _portals = {};
  Point start, end;

  Maze._(this.dimensions, this._tiles, { multilevel = false }) {
    for (var position in _tiles.keys.where(isOpen)) {
      final portal = _getPortal(position);
      if (portal == null) {
        continue;
      }
      if (portal.name == "AA") {
        checkState(start == null);
        start = position;
      } else if (portal.name == "ZZ") {
        checkState(end == null);
        end = position;
      } else {
        _portals[position] = portal;
      }
    }
  }

  Portal _getPortal(Point position) {
    for (var adjacent in position.adjacent.where(_contains)) {
      final first = _get(adjacent);
      if (!_isLetter(first)) {
        continue;
      }
      final next = adjacent + (adjacent - position);
      if (!_contains(next)) {
        continue;
      }
      final second = _get(next);
      if (!_isLetter(second)) {
        continue;
      }
      return Portal(([first, second]..sort()).join());
    }
    return null;
  }

  bool _isLetter(String tile) => tile.codeUnitAt(0) >= 65 && tile.codeUnitAt(0) <= 90;

  static Maze parse(String s, { int trim = 0, bool multilevel = false }) {
    final tiles = <Point, String>{};
    final rows = s.split("\n").where(isNotBlank).map((row) => row.substring(trim)).toList();
    for (var y = 0; y < rows.length; ++y) {
      for (var x = 0; x < rows[y].length; ++x) {
        tiles[Point(x, y)] = rows[y][x];
      }
    }
    final dimensions = Point(iterables.max(rows.map((row) => row.length)), rows.length);
    return multilevel ? MultiMaze._(dimensions, tiles) : Maze._(dimensions, tiles);
  }

  bool _contains(Point position) {
    return position.x >= 0 && position.x < dimensions.x
        && position.y >= 0 && position.y < dimensions.y;
  }

  bool isOpen(Point position) {
    return _get(position) == ".";
  }

  String _get(Point position) {
    _checkPosition(position);
    return _tiles[position];
  }

  void _checkPosition(Point position) => checkArgument(_contains(position), message: "invalid position: $position");

  int solve() {
    final minSteps = <Point, int>{};
    final queue = PriorityQueue<Path>((left, right) => left.steps.compareTo(right.steps));
    queue.add(Path(start));
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (minSteps.containsKey(current.position) && minSteps[current.position] < current.steps) {
        continue;
      }
      minSteps[current.position] = current.steps;
      if (current.position == end) {
        break;
      }
      final shortcut = teleport(current.position);
      if (shortcut != null) {
        queue.add(current.next(shortcut));
      }
      for (var adjacent in current.position.adjacent) {
        if (isOpen(adjacent)) {
          queue.add(current.next(adjacent));
        }
      }
    }
    return minSteps[end];
  }

  Point teleport(Point from) {
    final portal = _portals[from];
    if (portal == null) {
      return null;
    }
    return _portals.entries
        .firstWhere((entry) => entry.value.name == portal.name && entry.key != from)
        .key;
  }
}

class MultiMaze extends Maze {

  MultiMaze._(Point dimensions, Map<Point, String> tiles) : super._(dimensions, tiles);

  @override
  Portal _getPortal(Point position) {
    for (var adjacent in position.adjacent.where(_contains)) {
      final first = _get(adjacent);
      if (!_isLetter(first)) {
        continue;
      }
      final next = adjacent + (adjacent - position);
      if (!_contains(next)) {
        continue;
      }
      final second = _get(next);
      if (!_isLetter(second)) {
        continue;
      }
      final outside = next.x == 0 || next.x == dimensions.x - 1 ||
        next.y == 0 || next.y == dimensions.y - 1;
      return Portal(([first, second]..sort()).join(), outside ? -1 : 1);
    }
    return null;
  }

  @override
  int solve() {
    final minSteps = <int, Map<Point, int>>{};
    final queue = PriorityQueue<Path>((left, right) => left.steps.compareTo(right.steps));
    queue.add(Path(start));
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (!minSteps.containsKey(current.level)) {
        minSteps[current.level] = {};
      }
      if (minSteps[current.level].containsKey(current.position) && minSteps[current.level][current.position] < current.steps) {
        continue;
      }
      minSteps[current.level][current.position] = current.steps;
      if (current.level == 0 && current.position == end) {
        break;
      }
      final shortcut = multiteleport(current);
      if (shortcut != null) {
        queue.add(shortcut);
      }
      for (var adjacent in current.position.adjacent) {
        if (isOpen(adjacent)) {
          queue.add(current.next(adjacent));
        }
      }
    }
    return minSteps[0][end];
  }

  Path multiteleport(Path from) {
    final portal = _portals[from.position];
    if (portal == null) {
      return null;
    }
    if (from.level + portal.direction < 0) {
      return null;
    }
    final to = _portals.entries
      .firstWhere((entry) => entry.value.name == portal.name && entry.key != from.position)
      .key;
    return from.next(to, from.level + portal.direction);
  }
}

class Portal extends Equatable {

  final String name;
  final int direction;

  Portal(this.name, [ this.direction = 0 ]);

  @override
  List<Object> get props => [name, direction];

  @override
  String toString() => "$name ($direction)";
}

class Path extends Equatable {

  final Point position;
  final int steps;
  final int level;

  Path(this.position, [ this.steps = 0, this.level = 0 ]);

  Path next(Point to, [ int level ]) => Path(to, steps + 1, level ?? this.level);

  @override
  List<Object> get props => [position, steps, level];

  @override
  String toString() => "$position in level $level after $steps steps";
}

class Point extends Equatable {

  final int x, y;

  const Point(this.x, this.y);

  @override
  List<Object> get props => [x, y];

  Set<Point> get adjacent => {
    Point(x, y - 1),
    Point(x, y + 1),
    Point(x - 1, y),
    Point(x + 1, y)
  };

  Point operator-(Point subtrahend) {
    return Point(x - subtrahend.x, y - subtrahend.y);
  }

  Point operator+(Point addend) {
    return Point(x + addend.x, y + addend.y);
  }

  @override
  String toString() => "($x, $y)";
}
