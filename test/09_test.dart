import 'dart:io';

import 'package:advent_of_code/intcode.dart';
import 'package:test/test.dart';

void main() {

  group("Day 9", () {

    List<int> run(List<int> codes, [ List<int> input = const []]) => Intcode(codes, input).run();

    test("copy self", () {
      const codes = [109, 1, 204, -1, 1001, 100, 1, 100, 1008, 100, 16, 101, 1006, 101, 0, 99];
      expect(run(codes), codes);
    });

    test("output a 16-digit number", () {
      const codes = [1102, 34915192, 34915192, 7, 4, 7, 99, 0];
      expect(run(codes), [1219070632396864]);
    });

    test("output a large number", () {
      const codes = [104, 1125899906842624, 99];
      expect(run(codes), [codes[1]]);
    });

    List<int> input() => File("data/09.txt")
      .readAsStringSync()
      .split(",")
      .map(int.parse)
      .toList();

    test("Part 1", () {
      expect(run(input(), [1]), [3497884671]);
    });

    test("Part 2", () {
      expect(run(input(), [2]), [46470]);
    });
  });
}
