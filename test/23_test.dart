import 'dart:collection';
import 'dart:io';

import 'package:advent_of_code/intcode.dart';
import 'package:quiver/check.dart';
import 'package:quiver/iterables.dart';
import 'package:test/test.dart';

void main() {

  group("Day 23", () {

    void run(Iterable<Node> nodes) {
      final network = Map.fromEntries(nodes.map((node) => MapEntry(node.id, node)));
      for (final node in cycle(network.values)) {
        for (final packet in node.run()) {
          if (!network.containsKey(packet.destination)) {
            throw packet.y;
          }
          network[packet.destination].receive(packet);
        }
      }
    }

    List<int> input() => File("data/23.txt")
      .readAsStringSync()
      .split(",")
      .map(int.parse)
      .toList();

    List<Computer> computers(int n) {
      final codes = input();
      return List.generate(n, (id) => Computer(id, codes));
    }

    test("Part 1", () {
      expect(() => run(computers(50)), throwsA(17849));
    });

    test("Part 2", () {
      final nodes = computers(50);
      expect(() => run([...nodes, NAT(nodes)]), throwsA(12235));
    });
  });
}

abstract class Node {

  final int id;

  Node(this.id);

  void receive(Packet packet);

  List<Packet> run();
}

class Computer extends Node {

  final Intcode _intcode;
  final Queue<Packet> _queue = Queue<Packet>();

  Computer(int id, List<int> codes) : _intcode = Intcode(codes, []), super(id) {
    _intcode.addInput(id);
    final output =_intcode.run();
    checkState(output.isEmpty);
  }

  bool get isIdle => _queue.isEmpty;

  void receive(Packet packet) {
    _queue.addFirst(packet);
  }

  List<Packet> run() {
    if (_queue.isNotEmpty) {
      final input = _queue.removeLast();
      _intcode.addInput(input.x);
      _intcode.addInput(input.y);
    } else {
      _intcode.addInput(-1);
    }
    return partition(_intcode.run(), 3)
      .map((output) => Packet(output[0], output[1], output[2]))
      .toList();
  }
}

class NAT extends Node {

  final List<Computer> _members;
  Packet _lastReceived;
  Packet _lastSent;

  NAT(this._members) : super(255);

  @override
  void receive(Packet packet) {
    _lastReceived = packet;
  }

  @override
  List<Packet> run() {
    if (!_members.any((node) => !node.isIdle)) {
      if (_lastSent?.y == _lastReceived?.y) {
        throw _lastSent.y;
      }
      _lastSent = Packet(0, _lastReceived.x, _lastReceived.y);
      return [_lastSent];
    }
    return [];
  }
}

class Packet {

  final int destination;
  final int x;
  final int y;

  Packet(this.destination, this.x, this.y);
}
