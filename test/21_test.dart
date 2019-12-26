import 'dart:io';

import 'package:advent_of_code/intcode.dart';
import 'package:test/test.dart';

void main() {

  group("Day 21", () {

    List<int> input() => File("data/21.txt")
      .readAsStringSync()
      .split(",")
      .map(int.parse)
      .toList();

    List<int> toChars(String s) => s
      .split("")
      .map((char) => char.codeUnitAt(0))
      .toList();

    String toString(List<int> chars) => chars
      .map((char) => String.fromCharCode(char)).join("");

    int run(List<String> program) {
      final code = toChars([...program, ""].join("\n"));
      final output = Intcode(input(), code).run();
      if (output.last < 128) {
        print(toString(output));
        return -1;
      }
      return output.last;
    }

    test("Part 1", () {
      expect(run([
        "OR A T",
        "AND B T",
        "AND C T",
        "NOT T J",
        "AND D J",
        "WALK",
      ]), 19352493);
    });

    test("Part 2", () {
      expect(run([
        "OR A T",
        "AND B T",
        "AND C T",
        "NOT T J",
        "AND D J",
        "OR E T",
        "OR H T",
        "AND T J",
        "RUN",
      ]), 1141896219);
    });
  });
}
