import 'dart:io';

import 'package:test/test.dart';

void main() {

  group("Day 2", () {

    int Function(int, int) operator(int code) {
      switch (code) {
        case 1: return (a, b) => a + b;
        case 2: return (a, b) => a * b;
        case 99: return null;
        default: throw ArgumentError("Invalid code: $code");
      }
    }

    List<int> process(List<int> input) {
      var processed = List.of(input);
      for (var i = 0; i + 3 < processed.length; i += 4) {
        var f = operator(processed[i]);
        if (f == null) {
          break;
        }
        var subject = processed[processed[i + 1]];
        var verb = processed[processed[i + 2]];
        processed[processed[i + 3]] = f(subject, verb);
      }
      return processed;
    }

    test("process input", () {
      expect(process([1, 0, 0, 0, 99]), [2, 0, 0, 0, 99], reason: "1 + 1 = 2");
      expect(process([2, 3, 0, 3, 99]), [2, 3, 0, 6, 99], reason: "3 * 2 = 6");
      expect(process([2, 4, 4, 5, 99, 0]), [2, 4, 4, 5, 99, 9801], reason: "99 * 99 = 9801");
      expect(process([1, 1, 1, 4, 99, 5, 6, 0, 99]), [30, 1, 1, 4, 2, 5, 6, 0, 99]);
      expect(process([1, 9, 10, 3, 2, 3, 11, 0, 99, 30, 40, 50]), [3500, 9, 10, 70, 2, 3, 11, 0, 99, 30, 40, 50]);
    });

    List<int> input() {
      return File("data/02.txt")
        .readAsStringSync()
        .split(",")
        .map(int.parse)
        .toList();
    }

    int attempt(int subject, int verb) {
      var data = input();
      data[1] = subject;
      data[2] = verb;
      return process(data)[0];
    }

    test("Part 1", () {
      var answer = attempt(12, 2);
      expect(answer, 3760627);
    });

    test("Part 2", () {
      int answer;
      for (var noun = 0; noun < 100; ++noun) {
        for (var verb = 0; verb < 100; ++verb) {
          if (attempt(noun, verb) == 19690720) {
            answer = 100 * noun + verb;
          }
        }
      }
      expect(answer, 7195);
    });
  });
}
