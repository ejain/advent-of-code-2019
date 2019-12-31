import 'dart:io';

import 'package:advent_of_code/intcode.dart';
import 'package:test/test.dart';

void main() {

  group("Day 5", () {

    List<int> run(List<int> codes, List<int> inputs) => Intcode(codes, inputs).run();

    test("parse instructions", () {
      expect(Instruction.parse(99), Instruction(99, const []));
      expect(Instruction.parse(1002), Instruction(2, const [PositionMode(), ImmediateMode()]));
      expect(Instruction.parse(10199), Instruction(99, const [ImmediateMode(), PositionMode(), ImmediateMode()]));
    });

    test("input the output", () {
      expect(run([3, 0, 4, 0, 99], [42]), [42]);
    });

    test("multiply using both position and immediate modes", () {
      expect(run([1002, 4, 3, 4, 33], []), <int>[]);
    });

    List<int> input() => File("data/05.txt")
      .readAsStringSync()
      .split(",")
      .map(int.parse)
      .toList();

    test("Part 1", () {
      expect(run(input(), [1]), [0, 0, 0, 0, 0, 0, 0, 0, 0, 13978427]);
    });

    test("jump if false, position mode", () {
      final codes = [3, 12, 6, 12, 15, 1, 13, 14, 13, 4, 13, 99, -1, 0, 1, 9];
      expect(run(codes, [0]), [0], reason: "input is zero");
      expect(run(codes, [42]), [1], reason: "input is non-zero");
    });

    test("jump if true, immediate mode", () {
      const codes = [3, 3, 1105, -1, 9, 1101, 0, 0, 12, 4, 12, 99, 1];
      expect(run(codes, [0]), [0], reason: "input is zero");
      expect(run(codes, [7]), [1], reason: "input is non-zero");
    });

    test("less than, position mode", () {
      const codes = [3, 9, 7, 9, 10, 9, 4, 9, 99, -1, 8];
      expect(run(codes, [7]), [1], reason: "input is less than 8");
      expect(run(codes, [8]), [0], reason: "input is 8");
    });

    test("less than, immediate mode", () {
      const codes = [3, 3, 1107, -1, 8, 3, 4, 3, 99];
      expect(run(codes, [7]), [1], reason: "input is less than 8");
      expect(run(codes, [8]), [0], reason: "input is 8");
    });

    test("equals, position mode", () {
      const codes = [3, 9, 8, 9, 10, 9, 4, 9, 99, -1, 8];
      expect(run(codes, [8]), [1], reason: "input is 8");
      expect(run(codes, [9]), [0], reason: "input is not 8");
    });

    test("equals, immediate mode", () {
      const codes = [3, 3, 1108, -1, 8, 3, 4, 3, 99];
      expect(run(codes, [8]), [1], reason: "input is 8");
      expect(run(codes, [9]), [0], reason: "input is not 8");
    });

    test("combined test", () {
      const codes = [3, 21, 1008, 21, 8, 20, 1005, 20, 22, 107, 8, 21, 20, 1006,
        20, 31, 1106, 0, 36, 98, 0, 0, 1002 ,21 ,125, 20, 4, 20, 1105, 1, 46,
        104, 999, 1105, 1, 46, 1101, 1000, 1, 20, 4, 20, 1105, 1, 46, 98, 99];
      expect(run(codes, [7]), [999], reason: "input is less than 8");
      expect(run(codes, [8]), [1000], reason: "input is 8");
      expect(run(codes, [9]), [1001], reason: "input is greater than 8");
    });

    test("Part 2", () {
      expect(run(input(), [5]), [11189491]);
    });
  });
}
