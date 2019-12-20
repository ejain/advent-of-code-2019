import 'dart:io';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:quiver/check.dart';
import 'package:quiver/collection.dart';
import 'package:test/test.dart';

void main() {

  group("Day 18", () {

    test("parse grid", () {
      final grid = Grid.parse("""
        #########
        #b.A.@.a#
        #########
      """);
      expect(grid.dimensions, Point(9, 3));
      expect(grid.entrance, Point(5, 1));
      expect(grid.keys, {Point(1, 1), Point(7, 1)});
    });

    test("build graph", () {
      final grid = Grid.parse("""
        ######
        #a...#
        #.##.#
        #@#cB#
        #bA#.#
        ######
      """);
      final graph = grid.toGraph();
      expect(graph.targets, {Node("a"), Node("b"), Node("c")});
      expect(graph.getEdge(Node("@"), Node("a")), Edge(2, {}));
      expect(graph.getEdge(Node("b"), Node("c")), Edge(9, {"b"}));
    });

    test("solve graph (1)", () {
      final grid = Grid.parse("""
        #########
        #b.A.@.a#
        #########
      """);
      final graph = grid.toGraph();
      expect(graph.solve().steps, 8);
    });

    test("solve graph (2)", () {
      final grid = Grid.parse("""
        ########################
        #f.D.E.e.C.b.A.@.a.B.c.#
        ######################.#
        #d.....................#
        ########################
      """);
      final graph = grid.toGraph();
      expect(graph.solve().steps, 86);
    });

    test("solve graph (3)", () {
      final grid = Grid.parse("""
        ########################
        #...............b.C.D.f#
        #.######################
        #.....@.a.B.c.d.A.e.F.g#
        ########################
      """);
      final graph = grid.toGraph();
      expect(graph.solve().steps, 132);
    });

    test("solve graph (4)", () {
      final grid = Grid.parse("""
        #################
        #i.G..c...e..H.p#
        ########.########
        #j.A..b...f..D.o#
        ########@########
        #k.E..a...g..B.n#
        ########.########
        #l.F..d...h..C.m#
        #################
      """);
      final graph = grid.toGraph();
      expect(graph.solve().steps, 136);
    });

    test("solve graph (5)", () {
      final grid = Grid.parse("""
        ########################
        #@..............ac.GI.b#
        ###d#e#f################
        ###A#B#C################
        ###g#h#i################
        ########################
      """);
      final graph = grid.toGraph();
      expect(graph.solve().steps, 81);
    });

    Grid input() => Grid.parse(File("data/18.txt").readAsStringSync());

    test("Part 1", () {
      final grid = input();
      final graph = grid.toGraph();
      expect(graph.solve().steps, 3512);
    }, skip: true); // slow (~2min)!

    List<Grid> split(Grid grid) {
      final center = grid.entrance;
      grid.set(center, "#");
      grid.set(Point(center.x, center.y - 1), "#");
      grid.set(Point(center.x + 1, center.y - 1), "@");
      grid.set(Point(center.x + 1, center.y), "#");
      grid.set(Point(center.x + 1, center.y + 1), "@");
      grid.set(Point(center.x, center.y + 1), "#");
      grid.set(Point(center.x - 1, center.y + 1), "@");
      grid.set(Point(center.x - 1, center.y), "#");
      grid.set(Point(center.x - 1, center.y - 1), "@");
      return [
        grid.subgrid(Point(0, 0), center),
        grid.subgrid(Point(0, center.y), Point(center.x, grid.dimensions.y - 1)),
        grid.subgrid(Point(center.x, 0), Point(grid.dimensions.x - 1, center.y)),
        grid.subgrid(center, Point(grid.dimensions.x - 1, grid.dimensions.y - 1))
      ];
    }

    int solveAll(List<Graph> graphs) {
      final allKeys = graphs.expand((graph) => graph.targets).map((node) => node.value).toSet();
      final nodes = List.generate(graphs.length, (_) => Node("@"));
      final sharedKeys = <String>{};
      var totalSteps = 0;
      for (var i = 0; sharedKeys.length < allKeys.length; ++i) {
        final graph = graphs[i % graphs.length];
        final node = nodes[i % nodes.length];
        final result = graph.solve(initialNode: node, initialKeys: sharedKeys);
        if (result != null && !sharedKeys.containsAll(result.keys)) {
          totalSteps += result.steps;
          sharedKeys.addAll(result.keys);
          nodes[i % nodes.length] = result.last;
        }
      }
      return totalSteps;
    }

    test("Part 2", () {
      final grid = input();
      final graphs = split(grid).map((subgrid) => subgrid.toGraph()).toList();
      expect(solveAll(graphs), 1514);
    });
  });
}

class Grid {

  final Point dimensions;
  final Map<Point, String> _tiles;

  Grid._(this.dimensions, this._tiles);

  static Grid parse(String s) {
    final tiles = <Point, String>{};
    final rows = s.trim().split("\n");
    for (var y = 0; y < rows.length; ++y) {
      final row = rows[y].trim();
      for (var x = 0; x < row.length; ++x) {
        tiles[Point(x, y)] = row[x];
      }
    }
    return Grid._(Point(rows.first.length, rows.length), tiles);
  }

  Point get entrance => _locate("@");

  Point _locate(String tile) => _tiles.entries.firstWhere((entry) => entry.value == tile)?.key;

  Set<Point> get keys => _tiles.entries.where((entry) => _isKey(entry.value)).map((entry) => entry.key).toSet();

  static bool _isDoor(String tile) => tile.codeUnitAt(0) >= 65 && tile.codeUnitAt(0) <= 90;

  static bool _isKey(String tile) => tile.codeUnitAt(0) >= 97 && tile.codeUnitAt(0) <= 122;

  static bool _isWall(String tile) => tile == "#";

  bool _contains(Point position) {
    return position.x >= 0 && position.x < dimensions.x
      && position.y >= 0 && position.y < dimensions.y;
  }

  String _get(Point position) {
    _checkPosition(position);
    return _tiles[position];
  }

  void set(Point position, String tile) {
    _checkPosition(position);
    _tiles[position] = tile;
  }

  void _checkPosition(Point position) => checkArgument(_contains(position), message: "invalid position: $position");

  Graph toGraph() {
    final graph = Graph();
    for (var position in [entrance, ...keys]) {
      _addEdges(graph, Node(_get(position)));
    }
    return graph;
  }

  void _addEdges(Graph graph, Node from) {
    final queue = PriorityQueue<GridPath>((a, b) => a.steps.compareTo(b.steps));
    queue.add(GridPath(_locate(from.value)));
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (var adjacent in current.position.adjacent) {
        if (!_contains(adjacent)) {
          continue;
        }
        final tile = _get(adjacent);
        if (_isWall(tile)) {
          continue;
        }
        if (current.seen.contains(adjacent)) {
          continue;
        }
        final next = current.next(adjacent);
        if (_isDoor(tile)) {
          next.keys.add(tile.toLowerCase());
        } else if (_isKey(tile)) {
          final prior = graph.getEdge(from, Node(tile));
          if (prior == null || current.steps < prior.steps) {
            final edge = Edge(current.steps + 1, current.keys);
            graph.addEdge(from, Node(tile), edge);
            if (from.value != "@") {
              graph.addEdge(Node(tile), from, edge);
            }
          }
        }
        queue.add(next);
      }
    }
  }

  Grid subgrid(Point upperLeft, Point lowerRight) {
    final dimensions = Point(lowerRight.x - upperLeft.x + 1, lowerRight.y - upperLeft.y + 1);
    final tiles = Map.fromEntries(_tiles.entries
      .where((entry) => entry.key.within(upperLeft, lowerRight))
      .map((entry) => MapEntry(entry.key - upperLeft, entry.value)));
    return Grid._(dimensions, tiles);
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    for (var y = 0; y < dimensions.y; ++y) {
      buffer.writeln(_tiles.values.skip(y * dimensions.x).take(dimensions.x).join());
    }
    return buffer.toString();
  }
}

class Point extends Equatable {

  final int x, y;

  const Point(this.x, this.y);

  @override
  List<Object> get props => [x, y];

  Set<Point> get adjacent => {
    Point(x, y - 1),
    Point(x, y + 1),
    Point(x - 1, y),
    Point(x + 1, y)
  };

  bool within(Point upperLeft, Point lowerRight) {
    return x >= upperLeft.x && x <= lowerRight.x
      && y >= upperLeft.y && y <= lowerRight.y;
  }

  Point operator-(Point subtrahend) {
    return Point(x - subtrahend.x, y - subtrahend.y);
  }

  @override
  String toString() => "($x, $y)";
}

class GridPath {

  final Point position;
  final Set<String> keys = TreeSet<String>();
  final Set<Point> seen = <Point>{};
  final int steps;

  GridPath(this.position, { Iterable<String> keys = const [], Iterable<Point> seen = const [], this.steps = 0 }) {
    this.keys.addAll(keys);
    this.seen.addAll(seen);
    this.seen.add(position);
  }

  GridPath next(Point position) => GridPath(position, keys: keys, seen: seen, steps: steps + 1);
}

class Graph {

  final Map<Node, Map<Node, Edge>> _edges = {};
  final Set<Node> targets = {};

  void addEdge(Node from, Node to, Edge edge) {
    if (!_edges.containsKey(from)) {
      _edges[from] = {};
    }
    _edges[from][to] = edge;
    targets.add(to);
  }

  Edge getEdge(Node from, Node to) {
    return _edges.containsKey(from) ? _edges[from][to] : null;
  }

  Set<Node> getNodes(Node from) {
    return _edges.containsKey(from) ? _edges[from].keys.toSet() : {};
  }

  Result solve({ Node initialNode = const Node("@"), Set<String> initialKeys = const {} }) {
    final queue = PriorityQueue<GraphPath>((a, b) => a.steps.compareTo(b.steps));
    queue.add(GraphPath(initialNode, keys: initialKeys));
    Result result;
    final minStepsTo = <String, int>{};
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (result == null || current.keys.length > result.keys.length || current.keys.length == result.keys.length && current.steps < result.steps) {
        result = Result(current.steps, current.node, current.keys);
      }
      if (current.keys.length == targets.length) {
        continue;
      }
      final key = "${current.node}-${current.keys}";
      if (minStepsTo[key] != null && minStepsTo[key] <= current.steps) {
        continue;
      } else {
        minStepsTo[key] = current.steps;
      }
      for (var to in getNodes(current.node)) {
        if (current.keys.contains(to.value)) {
          continue;
        }
        final edge = getEdge(current.node, to);
        if (!current.keys.containsAll(edge.requiredKeys)) {
          continue;
        }
        queue.add(GraphPath(to,
          keys: [...current.keys, to.value],
          steps: current.steps + edge.steps
        ));
      }
    }
    return result;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    for (var from in _edges.entries) {
      for (var to in from.value.entries) {
        buffer.writeln("${from.key} to ${to.key} = ${to.value}");
      }
    }
    return buffer.toString();
  }
}

class Node extends Equatable {

  final String value;

  const Node(this.value);

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
}

class Edge extends Equatable {

  final int steps;
  final Set<String> requiredKeys;

  Edge(this.steps, this.requiredKeys);

  Edge addStep() => Edge(steps + 1, requiredKeys);

  Edge requireKey(String key) => Edge(steps, {...requiredKeys, key});

  @override
  List<Object> get props => [steps, requiredKeys];

  @override
  String toString() => "{steps:$steps, keys:$requiredKeys}";
}

class GraphPath {

  final Node node;
  final Set<String> keys = TreeSet();
  final int steps;

  GraphPath(this.node, { Iterable<String> keys = const {}, this.steps = 0 }) {
    this.keys.addAll(keys);
  }
}

class Result {

  final int steps;
  final Node last;
  final Set<String> keys;

  Result(this.steps, this.last, this.keys);
}
