import 'package:test/test.dart';

typedef Validator = bool Function(Iterable<int> digits);

void main() {

  group("Day 4", () {

    Iterable<int> toDigits(int n) => n.toString().split("").map(int.parse);

    bool nonDecreasing(Iterable<int> digits) {
      var prevDigit;
      for (var digit in digits) {
        if (prevDigit != null && digit < prevDigit) {
          return false;
        }
        prevDigit = digit;
      }
      return true;
    }

    test("non-decreasing", () {
      expect(nonDecreasing(toDigits(123789)), isTrue);
      expect(nonDecreasing(toDigits(111111)), isTrue);
      expect(nonDecreasing(toDigits(223450)), isFalse);
    });

    bool hasRepeat(Iterable<int> digits) {
      var prevDigit;
      for (var digit in digits) {
        if (prevDigit != null && digit == prevDigit) {
          return true;
        }
        prevDigit = digit;
      }
      return false;
    }

    test("has repeat", () {
      expect(hasRepeat(toDigits(123789)), isFalse);
      expect(hasRepeat(toDigits(111111)), isTrue);
      expect(hasRepeat(toDigits(223450)), isTrue);
    });

    Iterable<int> generate(int begin, int end, Iterable<Validator> validators) sync* {
      for (var n = begin; n <= end; ++n) {
        var digits = toDigits(n);
        if (validators.every((validator) => validator(digits))) {
          yield n;
        }
      }
    }

    test("Part 1", () {
      var candidates = generate(153517, 630395, [nonDecreasing, hasRepeat]);
      expect(candidates.length, 1729);
    });

    bool hasSingleRepeat(Iterable<int> digits) {
      var prevDigit;
      var prevDigitRepeats;
      for (var digit in digits) {
        if (prevDigit != null && digit == prevDigit) {
          ++prevDigitRepeats;
        } else {
          if (prevDigitRepeats == 1) {
            return true;
          }
          prevDigitRepeats = 0;
        }
        prevDigit = digit;
      }
      return prevDigitRepeats == 1;
    }

    test("has single repeat", () {
      expect(hasSingleRepeat(toDigits(112233)), isTrue);
      expect(hasSingleRepeat(toDigits(123444)), isFalse);
      expect(hasSingleRepeat(toDigits(111122)), isTrue);
    });

    test("Part 2", () {
      var candidates = generate(153517, 630395, [nonDecreasing, hasSingleRepeat]);
      expect(candidates.length, 1172);
    });
  });
}
