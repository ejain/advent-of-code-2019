import 'dart:io';
import 'dart:math';

import 'package:quiver/check.dart';
import 'package:test/test.dart';

void main() {

  group("Day 16", () {

    Iterable<int> factors(int repeats) sync* {
      checkArgument(repeats > 0);
      const base = [0, 1, 0, -1];
      for (var i = 0; ; ++i) {
        for (var repeat = 0; repeat < repeats; ++repeat) {
          if (i > 0 || repeat > 0) {
            yield base[i % base.length];
          }
        }
      }
    }

    test("factors", () {
      expect(factors(1).take(4), [1, 0, -1, 0]);
      expect(factors(2).take(15), [0, 1, 1, 0, 0, -1, -1, 0, 0, 1, 1, 0, 0, -1, -1]);
    });

    Iterable<T> zip<T>(Iterable<T> a, Iterable<T> b, T f(T a, T b)) sync* {
      final ia = a.iterator;
      final ib = b.iterator;
      while (ia.moveNext() && ib.moveNext()) {
        yield f(ia.current, ib.current);
      }
    }

    test("zip", () {
      expect(zip([1, 2, 3], [0, 4], max), [1, 4]);
    });

    List<int> fft(List<int> input) {
      final output = <int>[];
      for (var i = 0; i < input.length; ++i) {
        final products = zip(input.skip(i), factors(i + 1).skip(i), (a, b) => a * b);
        output.add(products.reduce((a, b) => a + b).abs() % 10);
      }
      return output;
    }

    test("fft", () {
      expect(fft([1, 2, 3, 4, 5, 6, 7, 8]), [4, 8, 2, 2, 6, 1, 5, 8]);
      expect(fft([4, 8, 2, 2, 6, 1, 5, 8]), [3, 4, 0, 4, 0, 4, 3, 8]);
      expect(fft([3, 4, 0, 4, 0, 4, 3, 8]), [0, 3, 4, 1, 5, 5, 1, 8]);
      expect(fft([0, 3, 4, 1, 5, 5, 1, 8]), [0, 1, 0, 2, 9, 4, 9, 8]);
    });

    String decode(String input, { phases = 100 }) {
      var output = input.split("").map(int.parse).toList();
      for (var phase = 0; phase < phases; ++phase) {
        output = fft(output);
      }
      return output.join();
    }

    test("decode", () {
      expect(decode("80871224585914546619083218645595"), startsWith("24176176"));
      expect(decode("19617804207202209144916044189917"), startsWith("73745418"));
      expect(decode("69317163492948606335995924319873"), startsWith("52432133"));
    });

    String input() => File("data/16.txt")
      .readAsStringSync()
      .trim();

    test("Part 1", () {
      expect(decode(input()), startsWith("19239468"));
    });

    List<int> fftEstimate(List<int> input) {
      final output = <int>[];
      var sum = 0;
      for (var digit in input.reversed) {
        sum += digit;
        output.add(sum % 10);
      }
      return output.reversed.toList();
    }

    test("estimate the fft (accurate only in the second half of the output)", () {
      expect(fftEstimate([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]), [1, 0, 9, 8, 7, 6, 5, 4, 3, 2, 1]);
    });

    String offsetDecode(String input, { phases = 100 }) {
      final offset = int.parse(input.substring(0, 7));
      var signal = input.substring(offset).split("").map(int.parse).toList();
      for (var phase = 0; phase < phases; ++phase) {
        signal = fftEstimate(signal);
      }
      return signal.sublist(0, 8).join();
    }

    test("decode with offset", () {
      expect(offsetDecode("03036732577212944063491565474664" * 10000), "84462026");
      expect(offsetDecode("02935109699940807407585447034323" * 10000), "78725270");
      expect(offsetDecode("03081770884921959731165446850517" * 10000), "53553731");
    });

    test("Part 2", () {
      expect(offsetDecode(input() * 10000), "96966221");
    });
  });
}
