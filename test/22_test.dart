import 'dart:io';

import 'package:quiver/check.dart';
import 'package:test/test.dart';

void main() {

  group("Day 22", () {

    Iterable<Technique> parse(List<String> lines) sync* {
      final pattern = RegExp(r"^([\w\s]+?)(?: ([\-\d]+))?$");
      for (final line in lines) {
        final match = pattern.firstMatch(line);
        checkNotNull(match, message: "can't parse <$line>");
        switch (match.group(1)) {
          case "deal into new stack":
            yield DealIntoNewStack();
            break;
          case "cut":
            final n = BigInt.parse(match.group(2));
            yield CutN(n);
            break;
          case "deal with increment":
            final n = BigInt.parse(match.group(2));
            yield DealWithIncrementN(n);
            break;
          default:
            throw ArgumentError("unsupported technique <${match.group(1)}>");
        }
      }
    }

    List<int> apply(List<Technique> techniques, List<int> deck) {
      final shuffle = Shuffle.combine(techniques, BigInt.from(deck.length));
      return deck
        .map((card) => BigInt.from(card))
        .map(shuffle.apply)
        .map((card) => card.toInt())
        .toList();
    }

    test("deal into new stack", () {
      expect(apply([DealIntoNewStack()],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
    });

    test("deal into new stack, twice", () {
      expect(apply([DealIntoNewStack(), DealIntoNewStack()],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test("cut n", () {
      expect(apply([CutN(BigInt.from(3))],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [3, 4, 5, 6, 7, 8, 9, 0, 1, 2]);
    });

    test("cut n, negative", () {
      expect(apply([CutN(BigInt.from(-3))],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [7, 8, 9, 0, 1, 2, 3, 4, 5, 6]);
    });

    test("deal with increment", () {
      expect(apply([DealWithIncrementN(BigInt.from(3))],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [0, 7, 4, 1, 8, 5, 2, 9, 6, 3]);
    });

    test("deal with increment, large", () {
      expect(apply([DealWithIncrementN(BigInt.from(7))],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [0, 3, 6, 9, 2, 5, 8, 1, 4, 7]);
    });

    test("example #1", () {
      expect(apply([DealWithIncrementN(BigInt.from(7)), DealIntoNewStack(), DealIntoNewStack()],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [0, 3, 6, 9, 2, 5, 8, 1, 4, 7]);
    });

    test("example #2", () {
      expect(apply([CutN(BigInt.from(6)), DealWithIncrementN(BigInt.from(7)), DealIntoNewStack()],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [3, 0, 7, 4, 1, 8, 5, 2, 9, 6]);
    });

    final input = parse(File("data/22.txt").readAsLinesSync()).toList();

    test("Part 1", () {
      var deck = List.generate(10007, (i) => i);
      deck = apply(input, deck);
      expect(deck.indexOf(2019), 4775);
    });

    test("Part 2", () {
      final deckSize = BigInt.from(119315717514047);
      final position = BigInt.from(2020);
      final repeats = BigInt.from(101741582076661);
      final card = Shuffle.combine(input, deckSize).applyN(position, repeats);
      expect(card, BigInt.from(37889219674304));
    });
  });
}

class Shuffle {

  final BigInt deckSize;
  final BigInt a;
  final BigInt b;

  Shuffle._(this.deckSize, this.a, this.b);

  static Shuffle combine(List<Technique> techniques, BigInt deckSize) => techniques.reversed.fold(
    Shuffle._(deckSize, BigInt.one, BigInt.zero),
    (shuffle, technique) => technique.update(shuffle)
  );

  Shuffle update(BigInt a, BigInt b) => Shuffle._(deckSize, a % deckSize, b % deckSize);

  BigInt apply(BigInt position) => (a * position + b) % deckSize;

  BigInt applyN(BigInt position, BigInt n) {
    final an = a.modPow(n, deckSize);
    final sn = ((an - BigInt.one) * (a - BigInt.one).modInverse(deckSize)) % deckSize;
    return (an * position + sn * b) % deckSize;
  }
}

// ignore: one_member_abstracts
abstract class Technique {

  Shuffle update(Shuffle shuffle);
}

class DealIntoNewStack implements Technique {

  @override
  Shuffle update(Shuffle shuffle) {
    return shuffle.update(shuffle.a * -BigInt.one, shuffle.deckSize - BigInt.one - shuffle.b);
  }
}

class CutN implements Technique {

  final BigInt _n;

  CutN(this._n);

  @override
  Shuffle update(Shuffle shuffle) {
    return shuffle.update(shuffle.a, shuffle.b + _n);
  }
}

class DealWithIncrementN implements Technique {

  final BigInt _n;

  DealWithIncrementN(this._n);

  @override
  Shuffle update(Shuffle shuffle) {
    final i = _n.modInverse(shuffle.deckSize);
    return shuffle.update(shuffle.a * i, shuffle.b * i);
  }
}
