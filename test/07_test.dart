import 'dart:io';
import 'dart:math';

import 'package:advent_of_code/intcode.dart';
import 'package:quiver/iterables.dart' show cycle;
import 'package:test/test.dart';

void main() {

  group("Day 7", () {

    Iterable<List<T>> permute<T>(List<T> items, [ List<T> prefix = const [] ]) sync* {
      if (items.isEmpty) {
        yield prefix;
      }
      for (var i = 0; i < items.length; ++i) {
        for (var permutation in permute(items.sublist(0, i) + items.sublist(i + 1), List.of(prefix)..add(items[i]))) {
          yield permutation;
        }
      }
    }

    test("permute list", () {
      expect(permute([1, 2, 3]), allOf(hasLength(6), containsAll(<List<int>>[
        [1, 2, 3],
        [1, 3, 2],
        [2, 1, 3],
        [2, 3, 1],
        [3, 1, 2],
        [3, 2, 1]
      ])));
    });

    int calculateSignal(List<int> codes, List<int> settings) {
      return settings.map((setting) => Amplifier(codes, setting))
        .fold(0, (signal, amplifier) => amplifier.run(signal));
    }

    test("calculate signal", () {
      expect(calculateSignal([
        3, 15, 3, 16, 1002, 16, 10, 16, 1, 16, 15, 15, 4, 15, 99, 0, 0
      ], [4, 3, 2, 1, 0]), 43210);
    });

    int findMaxSignal(List<int> codes) {
      return permute([0, 1, 2, 3, 4])
        .map((settings) => calculateSignal(codes, settings))
        .reduce(max);
    }

    test("find max signal", () {
      expect(findMaxSignal([
        3, 15, 3, 16, 1002, 16, 10, 16, 1, 16, 15, 15, 4, 15, 99, 0, 0
      ]), 43210);
    });

    List<int> input() => File("data/07.txt")
      .readAsStringSync()
      .split(",")
      .map(int.parse)
      .toList();

    test("Part 1", () {
      expect(findMaxSignal(input()), 272368);
    });

    int calculateSignalInFeedbackLoopMode(List<int> codes, List<int> settings) {
      final amplifiers = settings.map((setting) => Amplifier(codes, setting)).toList();
      var signal = 0;
      for (var amplifier in cycle(amplifiers)) {
        final result = amplifier.run(signal);
        if (result == null) {
          break;
        }
        signal = result;
      }
      return signal;
    }

    test("calculate signal in feedback loop mode", () {
      expect(calculateSignalInFeedbackLoopMode([
        3, 26, 1001, 26, -4, 26, 3, 27, 1002, 27, 2, 27, 1, 27, 26, 27, 4, 27,
        1001, 28, -1, 28, 1005, 28, 6, 99, 0, 0, 5
      ], [9, 8, 7, 6, 5]), 139629729);
    });

    int findMaxSignalInFeedbackLoopMode(List<int> codes) {
      return permute([5, 6, 7, 8, 9])
        .map((settings) => calculateSignalInFeedbackLoopMode(codes, settings))
        .reduce(max);
    }

    test("find max signal in feedback loop mode", () {
      expect(findMaxSignalInFeedbackLoopMode([
        3, 26, 1001, 26, -4, 26, 3, 27, 1002, 27, 2, 27, 1, 27, 26, 27, 4, 27,
        1001, 28, -1, 28, 1005, 28, 6, 99, 0, 0, 5
      ]), 139629729);
    });

    test("Part 2", () {
      expect(findMaxSignalInFeedbackLoopMode(input()), 19741286);
    });
  });
}

class Amplifier {

  final Intcode _intcode;

  Amplifier(List<int> codes, int setting) : _intcode = Intcode(codes, [setting]);

  int run(int input) {
    _intcode.addInput(input);
    return _intcode.next();
  }
}
