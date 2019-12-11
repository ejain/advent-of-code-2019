import 'dart:io';

import 'package:quiver/check.dart';
import 'package:test/test.dart';

void main() {

  group("Day 6", () {

    test("satellite depth", () {
      final system = System.parse([
        "COM)A",
        "A)B",
        "A)C",
      ]);
      expect(system.depthOf("A"), 1);
      expect(system.depthOf("C"), 2);
      expect(() => system.depthOf("COM"), throwsArgumentError);
    });

    test("count direct and indirect orbits", () {
      expect(System.parse([
        "COM)B",
        "B)C",
        "C)D",
        "D)E",
        "E)F",
        "B)G",
        "G)H",
        "D)I",
        "E)J",
        "J)K",
        "K)L",
      ]).count(), 42);
    });

    System input() => System.parse(File("data/06.txt").readAsLinesSync());

    test("Part 1", () {
      expect(input().count(), 158090);
    });

    test("list direct and indirect orbits", () {
      final system = System.parse([
        "COM)A",
        "A)B",
        "A)C",
      ]);
      expect(system.orbitsFor("A"), ["COM"]);
      expect(system.orbitsFor("B"), ["A", "COM"]);
      expect(() => system.orbitsFor("COM"), throwsArgumentError);
    });

    test("find the distance between two satellites", () {
      final system = System.parse([
        "COM)A",
        "A)B",
        "B)C",
        "A)D",
        "D)E",
      ]);
      expect(system.distance("A", "A"), 0, reason: "same");
      expect(system.distance("A", "B"), 1, reason: "one down");
      expect(system.distance("B", "A"), 1, reason: "one up");
      expect(system.distance("C", "E"), 2, reason: "one up and one down");
    });

    test("Part 2", () {
      expect(input().distance("YOU", "SAN"), 241);
    });
  });
}

class System {

  final Map<String, String> _orbits;

  System.parse(Iterable<String> lines) : _orbits = Map.fromIterable(
    lines.map((line) => line.trim().split(")")),
    key: (tokens) => tokens[1],
    value: (tokens) => tokens[0]);

  int depthOf(String satellite) {
    checkArgument(_orbits.containsKey(satellite), message: "not a satellite: $satellite");
    var depth = -1;
    while (satellite != null) {
      satellite = _orbits[satellite];
      ++depth;
    }
    return depth;
  }

  int count() {
    return _orbits.keys.fold(0, (int total, String satellite) => total + depthOf(satellite));
  }

  List<String> orbitsFor(String satellite) {
    var orbit = _orbits[satellite];
    checkArgument(orbit != null, message: "not a satellite: $satellite");
    final path = <String>[];
    while (orbit != null) {
      path.add(orbit);
      orbit = _orbits[orbit];
    }
    return path;
  }

  int distance(String from, String to) {
    return from != to ? _distance(orbitsFor(from), orbitsFor(to)) : 0;
  }

  int _distance(List<String> pathFrom, List<String> pathTo) {
    while (pathFrom.isNotEmpty && pathTo.isNotEmpty && pathFrom.last == pathTo.last) {
      pathFrom.removeLast();
      pathTo.removeLast();
    }
    return pathFrom.length + pathTo.length;
  }
}
