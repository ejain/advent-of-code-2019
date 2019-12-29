import 'dart:io';

import 'package:advent_of_code/intcode.dart';
import 'package:test/test.dart';

void main() {

  group("Day 25", () {

    List<int> input() => File("data/25.txt")
        .readAsStringSync()
        .split(",")
        .map(int.parse)
        .toList();

    test("play", () {
      final program = Asciicode(input());
      stdout.writeln(program.run());
      while (!program.isTerminated) {
        stdout.write("> ");
        final instruction = stdin.readLineSync();
        stdout.writeln(program.run("$instruction\n"));
      }
    }, skip: true);

    Iterable<Set<T>> subsets<T>(List<T> items) sync* {
      yield {};
      for (var i = 0; i < items.length; ++i) {
        for (final subset in subsets(i + 1 < items.length ? items.sublist(i + 1) : const [])) {
          yield {items[i], ...subset};
        }
      }
    }

    test("subsets", () {
      expect(subsets([1, 2, 3, 4]), [
        <int>{},
        {1},
        {1, 2},
        {1, 2, 3},
        {1, 2, 3, 4},
        {1, 2, 4},
        {1, 3},
        {1, 3, 4},
        {1, 4},
        {2},
        {2, 3},
        {2, 3, 4},
        {2, 4},
        {3},
        {3, 4},
        {4},
      ]);
    });

    test("Part 1", () {

      var droid = Droid(Asciicode(input()))
        ..move(Door.south) // Engineering
        ..move(Door.south) // Arcade
        ..move(Door.south) // Crew Quarters
        ..take("fixed point")
        ..move(Door.south) // Passages
        ..take("festive hat")
        ..move(Door.west) // Navigation
        ..move(Door.west) // Corridor
        ..take("jam")
        ..move(Door.south) // Stables
        ..take("easter egg")
        ..move(Door.north) // (Corridor)
        ..move(Door.east) // (Navigation)
        ..move(Door.east) // (Passages)
        ..move(Door.north) // (Crew Quarters)
        ..move(Door.west) // Kitchen
        ..take("asterisk")
        ..move(Door.east) // (Crew Quarters)
        ..move(Door.north) // (Arcade)
        ..move(Door.west) // Science Lab
        ..move(Door.north) // Warp Drive Maintenance
        ..move(Door.north) // Sick Bay
        ..take("tambourine")
        ..move(Door.south) // (Warp Drive Maintenance)
        ..move(Door.south) // (Science Lab)
        ..move(Door.east) // (Arcade)
        ..move(Door.north) // (Engineering)
        ..move(Door.west) // Hallway
        ..move(Door.south) // Gift Wrapping Center
        ..take("antenna")
        ..move(Door.north) // (Hallway)
        ..move(Door.west) // Observatory
        ..move(Door.west) // Storage
        ..take("space heater")
        ..move(Door.west) // Security Checkpoint
      ;

      for (final items in subsets(droid.inventory)) {
        droid.inventory.forEach(droid.drop);
        items.forEach(droid.take);
        droid.move(Door.west);
        if (droid.isTerminated) {
          break;
        }
      }

      expect(droid.room.description, contains("You may proceed."));
      expect(droid.room.description, contains("2147485856"));
      expect(droid.inventory, {"fixed point", "easter egg", "tambourine", "space heater"});
    });
  });
}

class Asciicode {

  final Intcode intcode;

  Asciicode(List<int> codes) : intcode = Intcode(codes, []);

  String run([ String input = "" ]) {
    _toChars(input).forEach(intcode.addInput);
    return _toString(intcode.run());
  }

  static List<int> _toChars(String s) => s
    .split("")
    .map((char) => char.codeUnitAt(0))
    .toList();

  static String _toString(List<int> chars) => chars
    .map((char) => String.fromCharCode(char)).join("");

  bool get isTerminated => intcode.isTerminated;
}

abstract class Instruction {

}

class Move implements Instruction {

  final Door _door;

  Move(this._door);

  @override
  String toString() => _door.name;
}

class Take implements Instruction {

  final String _item;

  Take(this._item);

  @override
  String toString() => "take $_item";
}

class Drop implements Instruction {

  final String _item;

  Drop(this._item);

  @override
  String toString() => "drop $_item";
}

class Droid {

  final Asciicode _program;
  final Set<String> _inventory = {};
  Room _room;

  Droid(this._program) {
    _room = Room(_program.run());
  }

  void move(Door door) {
    _room = Room(_run(Move(door)));
  }

  void take(String item) {
    _run(Take(item));
    _inventory.add(item);
  }

  void drop(String item) {
    _run(Drop(item));
    _inventory.remove(item);
  }

  String _run(Instruction instruction) => _program.run("$instruction\n");

  List<String> get inventory => _inventory.toList();

  Room get room => _room;

  bool get isTerminated => _program.isTerminated;
}

enum Door { north, south, east, west }

extension DoorProperties on Door {

  String get name => toString().split(".")[1];
}

class Room {

  final String description;

  Room(this.description);
}
