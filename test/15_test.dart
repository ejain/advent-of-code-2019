import 'dart:io';
import 'dart:math';

import 'package:advent_of_code/intcode.dart';
import 'package:equatable/equatable.dart';
import 'package:test/test.dart';

void main() {

  group("Day 15", () {

    List<int> input() => File("data/15.txt")
      .readAsStringSync()
      .split(",")
      .map(int.parse)
      .toList();

    test("move robot", () {
      final robot = Robot(input());
      expect(robot.position, Point(0, 0));
      expect(robot.move(Heading.east), Status.moved);
      expect(robot.position, Point(1, 0));
    });

    test("Part 1", () {
      final robot = Robot(input());
      final hull = Hull();
      expect(hull.findOxygen(robot).length - 1, 220);
    });

    test("Part 2", () {
      final robot = Robot(input());
      final hull = Hull();
      hull.findOxygen(robot);
      expect(hull.oxygenate(), Duration(minutes: 334));
    });
  });
}

enum Heading {
  north, south, west, east
}

enum Status {
  blocked, moved, found
}

class Robot {

  final Intcode _intcode;
  final List<Point> _path;

  Robot._(this._intcode, this._path);

  Robot(Iterable<int> codes, [ Point position = const Point(0, 0) ]) : this._(Intcode(codes, []), [position]);

  Robot copy() => Robot._(_intcode.copy(), List.of(_path));

  List<Point> get path => List.of(_path);

  Point get position => _path.last;

  Status move(Heading heading) {
    _intcode.addInput(heading.index + 1);
    _path.add(position.move(heading));
    return Status.values[_intcode.next()];
  }
}

class Point extends Equatable {

  final int x, y;

  const Point(this.x, this.y);

  Point move(Heading heading) {
    switch (heading) {
      case Heading.north: return Point(x, y - 1);
      case Heading.south: return Point(x, y + 1);
      case Heading.west: return Point(x - 1, y);
      case Heading.east: return Point(x + 1, y);
      default: throw ArgumentError("unsupported heading: $heading");
    }
  }

  @override
  List<Object> get props => [x, y];

  @override
  String toString() => "($x, $y)";
}

enum Panel {
  open, wall, oxygen, unknown
}

extension PanelExtension on Panel {

  String toChar() {
    switch(this) {
      case Panel.open: return " ";
      case Panel.wall: return "█";
      case Panel.oxygen: return "o";
      default: return "░";
    }
  }
}

class Hull {

  final _panels = <Point, Panel>{};

  void map(Point position, Panel panel) => _panels[position] = panel;

  Panel get(Point position) => _panels[position] ?? Panel.unknown;

  List<Point> findOxygen(Robot robot) {
    var robots = [robot];
    List<Point> shortestPath;
    while (robots.isNotEmpty) {
      var active = <Robot>[];
      for (var robot in robots) {
        for (var heading in Heading.values) {
          final next = robot.copy();
          switch (next.move(heading)) {
            case Status.moved:
              if (get(next.position) == Panel.unknown) {
                active.add(next);
                map(next.position, Panel.open);
              }
              break;
            case Status.blocked:
              map(next.position, Panel.wall);
              break;
            case Status.found:
              map(next.position, Panel.oxygen);
              if (shortestPath == null || next.path.length < shortestPath.length) {
                shortestPath = next.path;
              }
              break;
          }
        }
      }
      robots = active;
    }
    return shortestPath;
  }

  Duration oxygenate() {
    var minutes = 0;
    while (true) {
      final next = <Point>{};
      for (var oxygenated in _findPanels(Panel.oxygen)) {
        for (var heading in Heading.values) {
          final neighbor = oxygenated.move(heading);
          if (get(neighbor) == Panel.open) {
            next.add(neighbor);
          }
        }
      }
      if (next.isEmpty) {
        break;
      }
      for (var position in next) {
        map(position, Panel.oxygen);
      }
      ++minutes;
    }
    return Duration(minutes: minutes);
  }

  Iterable<Point> _findPanels(Panel match) {
    return _panels.keys.where((position) => _panels[position] == match);
  }

  Point _topLeft() => Point(
    _panels.keys.map((point) => point.x).reduce(min),
    _panels.keys.map((point) => point.y).reduce(min)
  );

  Point _bottomRight() => Point(
    _panels.keys.map((point) => point.x).reduce(max),
    _panels.keys.map((point) => point.y).reduce(max)
  );

  @override
  String toString() {
    final buffer = StringBuffer();
    final topLeft = _topLeft();
    final bottomRight = _bottomRight();
    for (var y = topLeft.y; y <= bottomRight.y; ++y) {
      for (var x = topLeft.x; x <= bottomRight.x; ++x) {
        buffer.write(get(Point(x, y)).toChar());
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
