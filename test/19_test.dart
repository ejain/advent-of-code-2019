import 'dart:io';

import 'package:advent_of_code/intcode.dart';
import 'package:equatable/equatable.dart';
import 'package:test/test.dart';

void main() {

  group("Day 19", () {

    final beam = Beam(File("data/19.txt")
      .readAsStringSync()
      .split(",")
      .map(int.parse)
      .toList());

    test("Part 1", () {
      expect(beam.count(Point(50, 50)), 121);
    });

    test("fit", () {
      expect(beam.fit(Point(10, 10)), Point(142, 73));
    });

    test("Part 2", () {
      final topLeft = beam.fit(Point(100, 100));
      expect(topLeft, Point(1509, 773));
      expect(topLeft.x * 10000 + topLeft.y, 15090773);
    });
  });
}

class Beam {

  final List<int> _codes;

  Beam(this._codes);

  int count(Point extent) {
    var count = 0;
    for (var y = 0; y < extent.y; ++y) {
      for (var x = 0; x < extent.y; ++x) {
        if (_contains(x, y)) {
          ++count;
        }
      }
    }
    return count;
  }

  Point fit(Point dimensions) {
    var x = 0, y = 0;
    while (!_contains(x + dimensions.x - 1, y)) {
      ++y;
      while (!_contains(x, y + dimensions.y - 1)) {
        ++x;
      }
    }
    return Point(x, y);
  }

  bool _contains(int x, int y) {
    return Intcode(_codes, [x, y]).next() == 1;
  }
}

class Point extends Equatable {

  final int x, y;

  const Point(this.x, this.y);

  @override
  List<Object> get props => [x, y];

  @override
  String toString() => "($x, $y)";
}
