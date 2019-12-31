import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:quiver/check.dart';
import 'package:test/test.dart';

void main() {

  group("Day 14", () {

    test("parse reactions", () {
      final reactor = Reactor.parse("""
        10 ORE => 10 A
        1 ORE => 1 B
        7 A, 1 B => 1 C
        7 A, 1 C => 1 D
        7 A, 1 D => 1 E
        7 A, 1 E => 1 FUEL
      """);
      final expected = Reaction([
        Quantity(7, Chemical("A")),
        Quantity(1, Chemical("E"))
      ], 1.fuel);
      expect(reactor.findReaction(expected.product.chemical), expected);
    });

    test("calculate input #1", () {
      final reactor = Reactor.parse("""
        10 ORE => 10 A
        1 ORE => 1 B
        7 A, 1 B => 1 C
        7 A, 1 C => 1 D
        7 A, 1 D => 1 E
        7 A, 1 E => 1 FUEL
      """);
      expect(reactor.calculateInput(1.fuel), 31.ore);
    });

    test("calculate input #2", () {
      final reactor = Reactor.parse("""
        9 ORE => 2 A
        8 ORE => 3 B
        7 ORE => 5 C
        3 A, 4 B => 1 AB
        5 B, 7 C => 1 BC
        4 C, 1 A => 1 CA
        2 AB, 3 BC, 4 CA => 1 FUEL
      """);
      expect(reactor.calculateInput(1.fuel), 165.ore);
    });

    test("calculate input and output #3", () {
      final reactor = Reactor.parse("""
        157 ORE => 5 NZVS
        165 ORE => 6 DCFZ
        44 XJWVT, 5 KHKGT, 1 QDVJ, 29 NZVS, 9 GPVTF, 48 HKGWZ => 1 FUEL
        12 HKGWZ, 1 GPVTF, 8 PSHF => 9 QDVJ
        179 ORE => 7 PSHF
        177 ORE => 5 HKGWZ
        7 DCFZ, 7 PSHF => 2 XJWVT
        165 ORE => 2 GPVTF
        3 DCFZ, 7 NZVS, 5 HKGWZ, 10 PSHF => 8 KHKGT
      """);
      expect(reactor.calculateInput(1.fuel), 13312.ore);
      expect(reactor.calculateOutput(1.trillion.ore), 82892753.fuel);
    });

    test("calculate input and output #4", () {
      final reactor = Reactor.parse("""
        2 VPVL, 7 FWMGM, 2 CXFTF, 11 MNCFX => 1 STKFG
        17 NVRVD, 3 JNWZP => 8 VPVL
        53 STKFG, 6 MNCFX, 46 VJHF, 81 HVMC, 68 CXFTF, 25 GNMV => 1 FUEL
        22 VJHF, 37 MNCFX => 5 FWMGM
        139 ORE => 4 NVRVD
        144 ORE => 7 JNWZP
        5 MNCFX, 7 RFSQX, 2 FWMGM, 2 VPVL, 19 CXFTF => 3 HVMC
        5 VJHF, 7 MNCFX, 9 VPVL, 37 CXFTF => 6 GNMV
        145 ORE => 6 MNCFX
        1 NVRVD => 8 CXFTF
        1 VJHF, 6 MNCFX => 4 RFSQX
        176 ORE => 6 VJHF
      """);
      expect(reactor.calculateInput(1.fuel), 180697.ore);
      expect(reactor.calculateOutput(1.trillion.ore), 5586022.fuel);
    });

    test("calculate input and output #5", () {
      final reactor = Reactor.parse("""
        171 ORE => 8 CNZTR
        7 ZLQW, 3 BMBT, 9 XCVML, 26 XMNCP, 1 WPTQ, 2 MZWV, 1 RJRHP => 4 PLWSL
        114 ORE => 4 BHXH
        14 VRPVC => 6 BMBT
        6 BHXH, 18 KTJDG, 12 WPTQ, 7 PLWSL, 31 FHTLT, 37 ZDVW => 1 FUEL
        6 WPTQ, 2 BMBT, 8 ZLQW, 18 KTJDG, 1 XMNCP, 6 MZWV, 1 RJRHP => 6 FHTLT
        15 XDBXC, 2 LTCX, 1 VRPVC => 6 ZLQW
        13 WPTQ, 10 LTCX, 3 RJRHP, 14 XMNCP, 2 MZWV, 1 ZLQW => 1 ZDVW
        5 BMBT => 4 WPTQ
        189 ORE => 9 KTJDG
        1 MZWV, 17 XDBXC, 3 XCVML => 2 XMNCP
        12 VRPVC, 27 CNZTR => 2 XDBXC
        15 KTJDG, 12 BHXH => 5 XCVML
        3 BHXH, 2 VRPVC => 7 MZWV
        121 ORE => 7 VRPVC
        7 XCVML => 6 RJRHP
        5 BHXH, 4 VRPVC => 5 LTCX
      """);
      expect(reactor.calculateInput(1.fuel), 2210736.ore);
      expect(reactor.calculateOutput(1.trillion.ore), 460664.fuel);
    });

    Reactor input() => Reactor.parse(File("data/14.txt").readAsStringSync());

    test("Part 1", () {
      expect(input().calculateInput(1.fuel), 751038.ore);
    });

    test("Part 2", () {
      expect(input().calculateOutput(1.trillion.ore), 2074843.fuel);
    });
  });
}

class Chemical extends Equatable {

  static const fuel = Chemical("FUEL");
  static const ore = Chemical("ORE");

  final String _name;

  const Chemical(this._name);

  String get name => _name;

  @override
  List<Object> get props => [name];

  @override
  String toString() => _name;
}

class Quantity extends Equatable {

  final int _count;
  final Chemical _chemical;

  Quantity(this._count, this._chemical);

  static Quantity parse(String s) {
    final tokens = s.split(" ");
    checkArgument(tokens.length == 2, message: "can't parse: $s");
    return Quantity(int.parse(tokens[0]), Chemical(tokens[1]));
  }

  int get count => _count;

  Chemical get chemical => _chemical;

  Quantity operator *(int factor) => Quantity(_count * factor, _chemical);

  @override
  List<Object> get props => [_count, _chemical];

  @override
  String toString() => "$_count $chemical";
}

class Reaction extends Equatable {

  final List<Quantity> _reactants;
  final Quantity _product;

  Reaction(Iterable<Quantity> reactants, this._product) : _reactants = List.of(reactants);

  static Reaction parse(String s) {
    final sides = s.split(" => ");
    checkArgument(sides.length == 2, message: "can't parse: $s");
    final reactants = sides[0].split(", ").map(Quantity.parse).toList();
    final product = Quantity.parse(sides[1]);
    return Reaction(reactants, product);
  }

  List<Quantity> get reactants => List.of(_reactants);

  List<Quantity> get missingReactants => _reactants.where((reactant) => reactant.count > 0).toList();

  Quantity get product => _product;

  Reaction substitute(Quantity reactant, Iterable<Quantity> reactants) {
    return Reaction([...List.of(_reactants)..remove(reactant), ...reactants], _product).simplify();
  }

  Reaction simplify() {
    final counts = <Chemical, int>{};
    for (var reactant in reactants) {
      final count = counts[reactant.chemical] ?? 0;
      counts[reactant.chemical] = count + reactant.count;
    }
    return Reaction(counts.entries.map((entry) => Quantity(entry.value, entry.key)), _product);
  }

  Reaction operator +(Quantity reactant) {
    return Reaction([..._reactants, reactant], _product).simplify();
  }

  Reaction operator *(int factor) {
    return Reaction(_reactants.map((reactant) => reactant * factor).toList(), _product * factor);
  }

  @override
  List<Object> get props => [_reactants, _product];

  @override
  String toString() => "${_reactants.join(", ")} => $_product";
}

class Reactor {

  final Map<Chemical, Reaction> _reactions;

  Reactor(List<Reaction> reactions) :
    _reactions = Map.fromEntries(reactions.map((reaction) => MapEntry(reaction.product.chemical, reaction)));

  static Reactor parse(String s) {
    return Reactor(s.trim().split("\n").map((line) => line.trim()).map(Reaction.parse).toList());
  }

  Reaction findReaction(Chemical chemical) => _reactions[chemical];

  Quantity calculateInput(Quantity product) {
    var reaction = findReaction(product.chemical);
    if (reaction.product.count != product.count) {
      reaction *= product.count ~/ reaction.product.count;
    }
    reaction = _reduce(reaction);
    checkState(reaction.missingReactants.length == 1, message: "can't reduce: $reaction");
    return reaction.missingReactants.first;
  }

  Reaction _reduce(Reaction reaction) {
    while (reaction.missingReactants.length > 1) {
      for (var reactant in reaction.reactants) {
        final upstreamReaction = findReaction(reactant.chemical);
        if (upstreamReaction != null) {
          final factor = (reactant.count / upstreamReaction.product.count).ceil();
          final surplus = Quantity(reactant.count - factor * upstreamReaction.product.count, reactant.chemical);
          reaction = reaction.substitute(reactant, upstreamReaction.reactants.map((reactant) => reactant * factor));
          if (surplus.count.abs() > 0) {
            reaction += surplus;
          }
          break;
        }
      }
    }
    return reaction;
  }

  Quantity calculateOutput(Quantity input, [ Chemical chemical = Chemical.fuel ]) {
    final minOutput = calculateInput(Quantity(1, chemical));
    var maxOutput = minOutput.count;
    var lower = input.count ~/ minOutput.count;
    var upper = lower * 2;
    while (upper - lower > 1) {
      final count = (lower + upper) ~/ 2;
      final actual = calculateInput(Quantity(count, chemical));
      if (actual.count == input.count) {
        maxOutput = count;
        break;
      } else if (actual.count > input.count) {
        upper = count;
      } else if (actual.count < input.count) {
        lower = count;
        maxOutput = count;
      }
    }
    return Quantity(maxOutput, chemical);
  }

  @override
  String toString() => _reactions.values.join("\n");
}

extension IntExtension on int {

  Quantity get fuel => Quantity(this, Chemical.fuel);

  Quantity get ore => Quantity(this, Chemical.ore);

  int get trillion => this * 1000 * 1000 * 1000 * 1000;
}
