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
            yield CutN(int.parse(match.group(2)));
            break;
          case "deal with increment":
            yield DealWithIncrementN(int.parse(match.group(2)));
            break;
          default:
            throw ArgumentError("unsupported technique <${match.group(1)}>");
        }
      }
    }

    List<int> shuffle(Iterable<Technique> techniques, List<int> deck) {
      return techniques.fold(deck, (deck, technique) => technique.apply(deck));
    }

    test("deal into new stack", () {
      expect(shuffle([DealIntoNewStack()],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]);
    });

    test("deal into new stack, twice", () {
      expect(shuffle([DealIntoNewStack(), DealIntoNewStack()],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test("cut n", () {
      expect(shuffle([CutN(3)],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [3, 4, 5, 6, 7, 8, 9, 0, 1, 2]);
    });

    test("cut n, negative", () {
      expect(shuffle([CutN(-3)],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [7, 8, 9, 0, 1, 2, 3, 4, 5, 6]);
    });

    test("deal with increment", () {
      expect(shuffle([DealWithIncrementN(3)],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [0, 7, 4, 1, 8, 5, 2, 9, 6, 3]);
    });

    test("deal with increment, large", () {
      expect(shuffle([DealWithIncrementN(7)],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [0, 3, 6, 9, 2, 5, 8, 1, 4, 7]);
    });

    test("example #1", () {
      expect(shuffle([DealWithIncrementN(7), DealIntoNewStack(), DealIntoNewStack()],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [0, 3, 6, 9, 2, 5, 8, 1, 4, 7]);
    });

    test("example #2", () {
      expect(shuffle([CutN(6), DealWithIncrementN(7), DealIntoNewStack()],
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]),
        [3, 0, 7, 4, 1, 8, 5, 2, 9, 6]);
    });

    final input = parse(File("data/22.txt").readAsLinesSync()).toList();

    test("Part 1", () {
      var deck = List.generate(10007, (i) => i);
      deck = shuffle(input, deck);
      expect(deck.indexOf(2019), 4775);
    });

    List<int> undoEach(Technique technique, List<int> deck) {
      return List.generate(deck.length, (i) => technique.undo(deck.length, deck[i]));
    }

    test("reverse deal into new stack", () {
      expect(undoEach(DealIntoNewStack(),
        [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test("reverse cut n", () {
      expect(undoEach(CutN(3),
        [3, 4, 5, 6, 7, 8, 9, 0, 1, 2]),
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test("reverse cut n, negative", () {
      expect(undoEach(CutN(-3),
        [7, 8, 9, 0, 1, 2, 3, 4, 5, 6]),
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test("reverse deal with increment", () {
      expect(undoEach(DealWithIncrementN(3),
        [0, 7, 4, 1, 8, 5, 2, 9, 6, 3]),
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    int undo(List<Technique> techniques, int numCards, int position) {
      return techniques.reversed.fold(position, (position, technique) => technique.undo(numCards, position));
    }

    test("Part 2", () {
      const repeats = 101741582076661;
      const numCards = 119315717514047;
      var position = 2020;
      for (var i = 0; i < repeats; ++i) {
        position = undo(input, numCards, position);
      }
      expect(position, null);
    }, skip: true); // too slow!
  });
}

abstract class Technique {

  List<int> apply(List<int> deck);

  int undo(int numCards, int position);
}

class DealIntoNewStack implements Technique {

  const DealIntoNewStack();

  @override
  List<int> apply(List<int> deck) => deck.reversed.toList();

  @override
  int undo(int numCards, int position) => numCards - position - 1;
}

class CutN implements Technique {

  final int _n;

  const CutN(this._n);

  @override
  List<int> apply(List<int> deck) {
    if (_n > 0) {
      deck = deck.sublist(_n) + deck.sublist(0, _n);
    } else if (_n < 0) {
      deck = deck.sublist(deck.length + _n) + deck.sublist(0, deck.length + _n);
    }
    return deck;
  }

  @override
  int undo(int numCards, int position) => (position - _n) % numCards;
}

class DealWithIncrementN implements Technique {

  final int _n;

  const DealWithIncrementN(this._n);

  @override
  List<int> apply(List<int> deck) {
    final shuffled = List.filled(deck.length, 0);
    for (var i = 0; i < deck.length; ++i) {
      shuffled[(i * _n) % deck.length] = deck[i];
    }
    return shuffled;
  }

  @override
  int undo(int numCards, int position) {
    return position * _n % numCards;
  }
}
