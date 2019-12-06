import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:quiver/check.dart';
import 'package:test/test.dart';

void main() {

  group("Day 6", () {

    Body build(Iterable<Orbit> orbits) {
      final map = <String, Body>{};
      for (var orbit in orbits) {
        final parent = map.putIfAbsent(orbit.center, () => Body(orbit.center, []));
        final object = map.putIfAbsent(orbit.object, () => Body(orbit.object, []));
        checkState(object.parent == null, message: "${object.name} appears in multiple orbits");
        parent.objects.add(object);
        object.parent = parent;
      }
      return checkNotNull(map["COM"], message: "missing COM");
    }

    test("build bodies from orbits", () {
      final COM = build([
        Orbit("COM", "B"),
        Orbit("B", "C"),
        Orbit("C", "D"),
        Orbit("B", "E"),
      ]);
      expect(COM.toString(), "COM)[B)[C)[D], E]]");
    });

    int count(Body body, [int depth = 0]) {
      return body.objects.fold(depth, (orbits, object) => orbits + count(object, depth + 1));
    }

    test("count direct and indirect orbits", () {
      expect(count(build([
        Orbit("COM", "B"),
        Orbit("B", "C"),
        Orbit("C", "D"),
        Orbit("D", "E"),
        Orbit("E", "F"),
        Orbit("B", "G"),
        Orbit("G", "H"),
        Orbit("D", "I"),
        Orbit("E", "J"),
        Orbit("J", "K"),
        Orbit("K", "L"),
      ])), 42);
    });

    List<Orbit> input() => File("data/06.txt")
      .readAsLinesSync()
      .map(Orbit.parseLine)
      .toList();

    test("parse line", () {
      expect(Orbit.parseLine("COM)B"), Orbit("COM", "B"));
    });

    test("Part 1", () {
      expect(count(build(input())), 158090);
    });

    test("find bodies in direct and indirect orbits", () {
      final COM = build([
        Orbit("COM", "A"),
        Orbit("A", "B"),
        Orbit("B", "C"),
      ]);
      expect(COM.find("COM"), Body("COM"), reason: "self");
      expect(COM.find("C"), Body("C"), reason: "indirect orbit");
      expect(COM.find("X"), isNull, reason: "not in orbit");
    });

    int distance(Body from, Body to) {
      if (from == to) {
        return 0;
      }
      final distances = Map<Body, int>();
      for (var distance = 0; from != null; from = from.parent) {
        distances[from] = distance++;
      }
      for (var distance = 0; to != null; to = to.parent) {
        if (distances.containsKey(to)) {
          return distances[to] + distance;
        }
        ++distance;
      }
      return null;
    }

    test("find the distance between two bodies", () {
      final COM = build([
        Orbit("COM", "A"),
        Orbit("A", "B"),
        Orbit("A", "C"),
      ]);
      final A = COM.find("A");
      final B = COM.find("B");
      final C = COM.find("C");
      expect(distance(A, A), 0, reason: "same body");
      expect(distance(A, B), 1, reason: "one down");
      expect(distance(B, A), 1, reason: "one up");
      expect(distance(B, C), 2, reason: "one up and one down");
      expect(distance(A, Body("X")), isNull, reason: "disconnected");
    });

    test("Part 2", () {
      final COM = build(input());
      final YOU = COM.find("YOU").parent;
      final SAN = COM.find("SAN").parent;
      expect(distance(YOU, SAN), 241);
    });
  });
}

class Orbit extends Equatable {

  final String center;
  final String object;

  const Orbit(this.center, this.object);

  static Orbit parseLine(String line) {
    final tokens = line.trim().split(")");
    checkArgument(tokens.length == 2, message: "can't parse $line");
    return Orbit(tokens[0], tokens[1]);
  }

  @override
  List<Object> get props => [center, object];

  @override
  String toString() => "$center)$object";
}

class Body extends Equatable {

  final String name;
  final List<Body> objects;
  Body parent;

  Body(this.name, [ this.objects = const [] ]);

  Body find(String name) {
    if (name == this.name) {
      return this;
    }
    for (var object in objects) {
      final found = object.find(name);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  @override
  List<Object> get props => [name];

  @override
  String toString() => objects.isNotEmpty ? "$name)$objects" : name;
}
