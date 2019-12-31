import 'dart:io';

import 'package:test/test.dart';

void main() {

  group("Day 1", () {

    int calculateFuel(int mass, {bool includeFuelMass = false}) {
      var fuel = mass ~/ 3 - 2;
      if (includeFuelMass && fuel > 6) {
        fuel += calculateFuel(fuel, includeFuelMass: includeFuelMass);
      }
      return fuel;
    }

    test("calculate fuel from mass", () {
      expect(calculateFuel(12), 2);
      expect(calculateFuel(14), 2);
      expect(calculateFuel(1969), 654);
      expect(calculateFuel(100756), 33583);
    });

    test("calculate fuel from mass, including fuel mass", () {
      expect(calculateFuel(12, includeFuelMass: true), 2);
      expect(calculateFuel(1969, includeFuelMass: true), 966);
      expect(calculateFuel(100756, includeFuelMass: true), 50346);
    });

    List<int> input() => File("data/01.txt")
      .readAsLinesSync()
      .map(int.parse)
      .toList();

    test("Part 1", () {
      var answer = input()
        .map(calculateFuel)
        .reduce((a, b) => a + b);
      expect(answer, 3423279);
    });

    test("Part 2", () {
      var answer = input()
        .map((mass) => calculateFuel(mass, includeFuelMass: true))
        .reduce((a, b) => a + b);
      expect(answer, 5132018);
    });
  });
}
