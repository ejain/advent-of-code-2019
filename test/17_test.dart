import 'dart:io';
import 'dart:math';

import 'package:advent_of_code/intcode.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:quiver/check.dart';
import 'package:test/test.dart';

void main() {

  group("Day 17", () {

    test("parse scaffold", () {
      final scaffold = Scaffold.parse("""
        ..#..........
        ..#..........
        #######...###
        #.#...#...#.#
        #############
        ..#...#...#..
        ..#####...^..      
      """);
      expect(scaffold.dimensions, Point(13, 7));
      expect(scaffold.checksum, 76);
    });

    List<int> input() => File("data/17.txt")
      .readAsStringSync()
      .split(",")
      .map(int.parse)
      .toList();

    test("Part 1", () {
      final intcode = Intcode(input(), []);
      final scaffold = Scaffold.build(intcode.run());
      expect(scaffold.checksum, 3336);
    });

    List<Movement> parse(String s) => s.split(",").map(Movement.parse).toList();

    test("robot movements", () {
      final scaffold = Scaffold.parse("""
        #######...#####
        #.....#...#...#
        #.....#...#...#
        ......#...#...#
        ......#...###.#
        ......#.....#.#
        ^########...#.#
        ......#.#...#.#
        ......#########
        ........#...#..
        ....#########..
        ....#...#......
        ....#...#......
        ....#...#......
        ....#####......
      """);
      final robot = Robot(scaffold);
      robot.run();
      expect(robot.movements, parse("R8,R8,R4,R4,R8,L6,L2,R4,R4,R8,R8,R8,L6,L2"));
    });

    test("split", () {
      expect(Program.split([1, 2, 3, 4, 5], minLength: 2, maxLength: 4, maxCount: 3), {
        {[1, 2, 3], [4, 5]},
        {[1, 2], [3, 4, 5]}
      });
    });

    test("create a program from movements", () {
      final movements = parse("R8,R8,R4,R4,R8,L6,L2,R4,R4,R8,R8,R8,L6,L2");
      final program = Program.from(movements);
      expect(program.routines, [
        Routine("A", parse("R8,R8")),
        Routine("B", parse("R4,R4,R8")),
        Routine("C", parse("L6,L2"))
      ]);
      expect(program.main, [
        Routine("A", parse("R8,R8")),
        Routine("B", parse("R4,R4,R8")),
        Routine("C", parse("L6,L2")),
        Routine("B", parse("R4,R4,R8")),
        Routine("A", parse("R8,R8")),
        Routine("C", parse("L6,L2"))
      ]);
    });

    test("Part 2", () {
      final codes = input();
      final scaffold = Scaffold.build(Intcode(codes, []).run());
      final robot = Robot(scaffold);
      robot.run();
      final program = Program.from(robot.movements);
      final intcode = Intcode(codes, [...program.compile(), 110, 10]);
      intcode.set(0, 2);
      final output = intcode.run();
      expect(output.last, 597517);
    }, skip: true); // slow (>30s)!
  });
}

class Scaffold {

  final Point dimensions;
  final List<String> _layout;

  Scaffold(this.dimensions, Iterable<String> layout) : _layout = List.of(layout);

  static Scaffold build(Iterable<int> codes) {
    return parse(codes.map((code) => String.fromCharCode(code)).join());
  }

  static Scaffold parse(String s) {
    final rows = s.trim().split("\n");
    final layout = rows.expand((line) => line.trim().split(""));
    return Scaffold(Point(rows.first.length, rows.length), layout);
  }

  int get checksum => _iterate()
    .where(_isIntersection)
    .fold(0, (checksum, position) => checksum + position.x * position.y);

  Iterable<Point> _iterate() sync* {
    for (var y = 0; y < dimensions.y; ++y) {
      for (var x = 0; x < dimensions.x; ++x) {
        yield Point(x, y);
      }
    }
  }

  bool _isIntersection(Point position) {
    var connects = 0;
    if (_isNotEmpty(position)) {
      for (var heading in Heading.values) {
        if (_isNotEmpty(position.move(heading))) {
          ++connects;
        }
      }
    }
    return connects > 2;
  }

  bool _isNotEmpty(Point position) {
    return _contains(position) && _get(position) != ".";
  }

  bool _contains(Point position) {
    return position.x >= 0 && position.x < dimensions.x
        && position.y >= 0 && position.y < dimensions.y;
  }

  String _get(Point position) {
    checkArgument(_contains(position), message: "invalid position: $position");
    return _layout[position.y * dimensions.x + position.x];
  }

  Point get robot => _iterate().firstWhere((position) => _get(position) == "^");

  @override
  String toString() {
    final buffer = StringBuffer();
    for (var y = 0; y < dimensions.y; ++y) {
      final offset = y * dimensions.x;
      buffer.writeln(_layout.sublist(offset, offset + dimensions.x).join());
    }
    return buffer.toString();
  }
}

class Point extends Equatable {

  final int x, y;

  const Point(this.x, this.y);

  @override
  List<Object> get props => [x, y];

  Point move(Heading heading) {
    switch (heading) {
      case Heading.up: return Point(x, y - 1);
      case Heading.down: return Point(x, y + 1);
      case Heading.left: return Point(x - 1, y);
      case Heading.right: return Point(x + 1, y);
      default: throw ArgumentError("unsupported heading: $heading");
    }
  }

  @override
  String toString() => "($x, $y)";
}

class Robot {

  final Scaffold _scaffold;
  Point _position;
  var _heading = Heading.up;
  final _movements = <Movement>[];

  Robot(this._scaffold) : _position = _scaffold.robot;

  List<Movement> get movements => List.of(_movements);

  void run() {
    while (true) {
      Turn turn;
      if (_canMove(Turn.left)) {
        turn = Turn.left;
        _heading = _heading.turn(Turn.left);
      } else if (_canMove(Turn.right)) {
        turn = Turn.right;
        _heading = _heading.turn(Turn.right);
      } else {
        break;
      }
      var distance = -1;
      for (var next = _position; _scaffold._isNotEmpty(next); next = next.move(_heading)) {
        _position = next;
        ++distance;
      }
      _movements.add(Movement._(turn, distance));
    }
  }

  bool step() {
    if (_canMove(Turn.left)) {
      _move(Turn.left);
      return true;
    }
    if (_canMove(Turn.right)) {
      _move(Turn.right);
      return true;
    }
    return false;
  }

  bool _canMove(Turn turn) => _scaffold._isNotEmpty(_position.move(_heading.turn(turn)));

  void _move(Turn turn) {
    _heading = _heading.turn(turn);
    var distance = -1;
    for (var next = _position; _scaffold._isNotEmpty(next); next = next.move(_heading)) {
      _position = next;
      ++distance;
    }
    _movements.add(Movement._(turn, distance));
  }
}

class Program {

  final List<Routine> _main;

  Program(Iterable<Routine> main) : _main = List.of(main);

  List<Routine> get main => List.of(_main);

  List<Routine> get routines => {..._main}.toList();

  static Program from(List<Movement> movements) {
    Program shortest;
    for (var sublists in split(movements, maxLength: 5, maxCount: 3)) {
      final program = _createProgram(movements, _createRoutines(sublists));
      if (program.main.length <= 10) {
        if (shortest == null || program.compile().length <= shortest.compile().length) {
          shortest = program;
        }
      }
    }
    return shortest;
  }

  static Iterable<Set<List<T>>> split<T>(List<T> items, { int minLength = 2, int maxLength = 5, int maxCount = 3 }) sync* {
    checkArgument(items.length > 0);
    checkArgument(maxLength > 0);
    checkArgument(maxCount > 0);
    if (items.length >= minLength && items.length <= maxLength) {
      yield {items};
    }
    if (items.length > 1) {
      for (var i = minLength; (i < min(items.length, maxLength + 1)) && (i <= items.length - minLength); ++i) {
        final listEquals = ListEquality<T>();
        final head = items.sublist(0, i);
        for (var tail in split(items.sublist(i), minLength: minLength, maxLength: maxLength, maxCount: maxCount)) {
          final subsets = EqualitySet<List<T>>(listEquals);
          subsets.add(head);
          subsets.addAll(tail);
          if (subsets.length <= maxCount) {
            yield subsets;
          }
        }
      }
    }
  }

  static List<Routine> _createRoutines(Set<List<Movement>> sublists) {
    var n = 0;
    return sublists.map((movements) {
      final name = String.fromCharCode(_toChar("A") + n++);
      return Routine(name, movements);
    }).toList();
  }

  static Program _createProgram(List<Movement> movements, List<Routine> routines) {
    final main = <Routine>[];
    while (movements.isNotEmpty) {
      for (var routine in routines) {
        if (startsWith(movements, routine.movements)) {
          main.add(routine);
          movements = movements.sublist(routine.movements.length);
        }
      }
    }
    return Program(main);
  }

  static bool startsWith<T>(List<T> items, List<T> prefix) {
    return items.length >= prefix.length && const ListEquality().equals(items.sublist(0, prefix.length), prefix);
  }

  static int _toChar(String s) {
    checkArgument(s.length == 1);
    return s.codeUnitAt(0);
  }

  List<int> compile() => toString().split("").map(_toChar).toList();

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln(main.join(","));
    for (var proc in routines) {
      buffer.writeln(proc.movements.join(','));
    }
    return buffer.toString();
  }
}

class Movement extends Equatable {

  final Turn _turn;
  final int _distance;

  Movement._(this._turn, this._distance);

  static Movement parse(String s) {
    final turn = s[0] == "L" ? Turn.left : Turn.right;
    final distance = int.parse(s.substring(1));
    return Movement._(turn, distance);
  }

  Turn get turn => _turn;

  int get distance => _distance;

  @override
  List<Object> get props => [turn, distance];

  @override
  String toString() => "${turn.symbol()},$distance";
}

enum Turn { left, right }

extension TurnExtension on Turn {

  String symbol() => this == Turn.left ? "L" : "R";
}

class Routine extends Equatable {

  final String name;
  final List<Movement> _movements;

  Routine(this.name, Iterable<Movement> movements) : _movements = List.of(movements);

  List<Movement> get movements => List.of(_movements);

  @override
  List<Object> get props => [name, _movements];

  @override
  String toString() => name;
}

enum Heading { up, right, down, left }

extension HeadingExtension on Heading {

  Heading turn(Turn turn) {
    final direction = turn.index * 2 - 1; // -1 for left, 1 for right
    return Heading.values[(index + direction) % Heading.values.length];
  }
}
