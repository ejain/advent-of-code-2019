import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:quiver/check.dart';
import 'package:quiver/iterables.dart';
import 'package:test/test.dart';

void main() {

  group("Day 24", () {

    test("next state", () {

      var state = State.parse("""
        ....#
        #..#.
        #..##
        ..#..
        #....
      """);

      expect(state = state.next(), State.parse("""
        #..#.
        ####.
        ###.#
        ##.##
        .##..
      """), reason: "after 1 minute");

      expect(state = state.next(), State.parse("""
        #####
        ....#
        ....#
        ...#.
        #.###
      """), reason: "after 2 minutes");

      expect(state = state.next(), State.parse("""
        #....
        ####.
        ...##
        #.##.
        .##.#
      """), reason: "after 3 minutes");

      expect(state = state.next(), State.parse("""
        ####.
        ....#
        ##..#
        .....
        ##...
      """), reason: "after 4 minutes");
    });

    test("rate state", () {
      expect(State.parse("""
        .....
        .....
        .....
        #....
        .#...
      """).rate(), 2129920);
    });

    int findRepeat(State state) {
      final ratings = <int>{};
      while (true) {
        final rating = state.rate();
        if (ratings.contains(rating)) {
          return rating;
        }
        ratings.add(rating);
        state = state.next();
      }
    }

    test("find repeat", () {
      final state = State.parse("""
        ....#
        #..#.
        #..##
        ..#..
        #....
      """);
      expect(findRepeat(state), 2129920, reason: "rating of the first state that appears twice");
    });

    test("Part 1", () {
      final state = State.parse("""
        #####
        .....
        ....#
        #####
        .###.
      """);
      expect(findRepeat(state), 13500447, reason: "rating of the first state that appears twice");
    });

    RecursiveState next(RecursiveState state, int repeats) {
      return range(repeats).fold(state, (state, _) => state.next());
    }

    test("recursive state", () {
      final state = RecursiveState.parse("""
        ....#
        #..#.
        #..##
        ..#..
        #....
      """);
      expect(next(state, 10).count(), 99, reason: "number of bugs after 10 minutes");
    });

    test("Part 2", () {
      final state = RecursiveState.parse("""
        #####
        .....
        ....#
        #####
        .###.
      """);
      expect(next(state, 200).count(), 2120, reason: "number of bugs after 200 minutes");
    });
  });
}

class State extends Equatable {

  final List<int> _tiles;
  final int _length;

  State(this._tiles) : _length = sqrt(_tiles.length).floor() {
    checkArgument(_tiles.length == _length * _length);
  }

  State.parse(String s) : this(_parseTiles(s));

  static List<int> _parseTiles(String s) {
    final tiles = <int>[];
    for (final line in s.trim().split("\n")) {
      for (final char in line.trim().split("")) {
        tiles.add(char == "#" ? 1 : 0);
      }
    }
    return tiles;
  }

  State next() {
    return State(_nextTiles());
  }

  List<int> _nextTiles() {
    final tiles = <int>[];
    for (var y = 0; y < _length; ++y) {
      for (var x = 0; x < _length; ++x) {
        final isEmpty = _get(x, y) == 0;
        final adjacent = _countAdjacent(x, y);
        final survive = !isEmpty && adjacent == 1 || isEmpty && adjacent > 0 && adjacent <= 2;
        tiles.add(survive ? 1 : 0);
      }
    }
    return tiles;
  }

  int _countAdjacent(int x, int y) =>
    _get(x, y - 1) +
    _get(x + 1, y) +
    _get(x, y + 1) +
    _get(x - 1, y);

  int _get(int x, int y) => _contains(x, y) ? _tiles[x + _length * y] : 0;

  bool _contains(int x, int y) =>
    x >= 0 && x < _length &&
    y >= 0 && y < _length;

  int rate() {
    var points = 0;
    for (var i = 0; i < _tiles.length; ++i) {
      points += _tiles[i] * pow(2, i);
    }
    return points;
  }

  @override
  List<Object> get props => [_tiles];

  @override
  String toString() {
    final buffer = StringBuffer();
    for (var i = 0; i < _tiles.length; ++i) {
      if (i > 0 && i % _length == 0) {
        buffer.writeln();
      }
      buffer.write(_tiles[i] == 1 ? "#" : ".");
    }
    return buffer.toString();
  }
}

// ignore: must_be_immutable
class RecursiveState extends State {

  final int depth;
  RecursiveState _parent;
  RecursiveState _child;

  RecursiveState(this.depth, List<int> tiles, [this._parent, this._child]) : super(tiles) {
    if (_parent != null) {
      _parent._child = this;
    }
    if (_child != null) {
      _child._parent = this;
    }
  }

  RecursiveState.empty({int length, int depth, RecursiveState parent, RecursiveState child}) :
    this(depth, List.filled(length * length, 0), parent, child);

  RecursiveState.parse(String s) : this(0, State._parseTiles(s));

  int get _middle => _length ~/ 2;

  @override
  RecursiveState next() {
    _parent = RecursiveState.empty(length: _length, depth: depth - 1, child: this);
    return _parent._next();
  }

  RecursiveState _next() {
    final tiles = _nextTiles();
    tiles[tiles.length ~/ 2] = 0;
    if (!tiles.any((tile) => tile > 0)) {
      if (_parent == null) {
        return _child._next();
      }
      if (_child == null) {
        return null;
      }
    }
    if (_child == null) {
      _child = RecursiveState.empty(length: _length, depth: depth + 1, parent: this);
    }
    return RecursiveState(depth, tiles, _parent, _child._next());
  }

  @override
  int _countAdjacent(int x, int y) =>
    super._countAdjacent(x, y)
    + _countAdjacentInParent(x, y)
    + _countAdjacentInChild(x, y);

  int _countAdjacentInParent(int x, int y) {
    var bugs = 0;
    if (_parent != null) {
      if (x - 1 < 0) {
        bugs += _parent._get(_middle - 1, _middle);
      }
      if (x + 1 >= _length) {
        bugs += _parent._get(_middle + 1, _middle);
      }
      if (y - 1 < 0) {
        bugs += _parent._get(_middle, _middle - 1);
      }
      if (y + 1 >= _length) {
        bugs += _parent._get(_middle, _middle + 1);
      }
    }
    return bugs;
  }

  int _countAdjacentInChild(int x, int y) {
    var bugs = 0;
    if (_child != null) {
      if (x + 1 == _middle && y == _middle) {
        for (var i = 0; i < _length; ++i) {
          bugs += _child._get(0, i);
        }
      }
      if (x - 1 == _middle && y == _middle) {
        for (var i = 0; i < _length; ++i) {
          bugs += _child._get(_length - 1, i);
        }
      }
      if (x == _middle && y + 1 == _middle) {
        for (var i = 0; i < _length; ++i) {
          bugs += _child._get(i, 0);
        }
      }
      if (x == _middle && y - 1 == _middle) {
        for (var i = 0; i < _length; ++i) {
          bugs += _child._get(i, _length - 1);
        }
      }
    }
    return bugs;
  }

  int count() {
    var bugs = _tiles.where((tile) => tile == 1).length;
    if (_child != null) {
      bugs += _child.count();
    }
    return bugs;
  }
}
