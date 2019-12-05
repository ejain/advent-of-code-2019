import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:quiver/check.dart';
import 'package:test/test.dart';

void main() {

  group("Day 5", () {

    List<int> run(List<int> codes, List<int> inputs) => Intcode(codes, inputs).run();

    test("parse instructions", () {
      expect(Instruction.parse(99), Instruction(99, []));
      expect(Instruction.parse(1002), Instruction(2, [Mode.position, Mode.immediate]));
      expect(Instruction.parse(10199), Instruction(99, [Mode.immediate, Mode.position, Mode.immediate]));
    });

    test("input the output", () {
      expect(run([3, 0, 4, 0, 99], [42]), [42]);
    });

    test("multiply using both position and immediate modes", () {
      expect(run([1002, 4, 3, 4, 33], []), []);
    });

    List<int> input() => File("data/05.txt")
      .readAsStringSync()
      .split(",")
      .map(int.parse)
      .toList();

    test("Part 1", () {
      expect(run(input(), [1]), [0, 0, 0, 0, 0, 0, 0, 0, 0, 13978427]);
    });

    test("jump if false, position mode", () {
      final codes = [3, 12, 6, 12, 15, 1, 13, 14, 13, 4, 13, 99, -1, 0, 1, 9];
      expect(run(codes, [0]), [0], reason: "input is zero");
      expect(run(codes, [42]), [1], reason: "input is non-zero");
    });

    test("jump if true, immediate mode", () {
      const codes = [3, 3, 1105, -1, 9, 1101, 0, 0, 12, 4, 12, 99, 1];
      expect(run(codes, [0]), [0], reason: "input is zero");
      expect(run(codes, [7]), [1], reason: "input is non-zero");
    });

    test("less than, position mode", () {
      const codes = [3, 9, 7, 9, 10, 9, 4, 9, 99, -1, 8];
      expect(run(codes, [7]), [1], reason: "input is less than 8");
      expect(run(codes, [8]), [0], reason: "input is 8");
    });

    test("less than, immediate mode", () {
      const codes = [3, 3, 1107, -1, 8, 3, 4, 3, 99];
      expect(run(codes, [7]), [1], reason: "input is less than 8");
      expect(run(codes, [8]), [0], reason: "input is 8");
    });

    test("equals, position mode", () {
      const codes = [3, 9, 8, 9, 10, 9, 4, 9, 99, -1, 8];
      expect(run(codes, [8]), [1], reason: "input is 8");
      expect(run(codes, [9]), [0], reason: "input is not 8");
    });

    test("equals, immediate mode", () {
      const codes = [3, 3, 1108, -1, 8, 3, 4, 3, 99];
      expect(run(codes, [8]), [1], reason: "input is 8");
      expect(run(codes, [9]), [0], reason: "input is not 8");
    });

    test("combined test", () {
      const codes = [3, 21, 1008, 21, 8, 20, 1005, 20, 22, 107, 8, 21, 20, 1006,
        20, 31, 1106, 0, 36, 98, 0, 0, 1002 ,21 ,125, 20, 4, 20, 1105, 1, 46,
        104, 999, 1105, 1, 46, 1101, 1000, 1, 20, 4, 20, 1105, 1, 46, 98, 99];
      expect(run(codes, [7]), [999], reason: "input is less than 8");
      expect(run(codes, [8]), [1000], reason: "input is 8");
      expect(run(codes, [9]), [1001], reason: "input is greater than 8");
    });

    test("Part 2", () {
      expect(run(input(), [5]), [11189491]);
    });
  });
}

class Intcode {

  final List<int> _codes;
  final List<int> _inputs;
  final List<int> _outputs = [];
  var _pointer = 0;

  Intcode(List<int> codes, List<int> inputs) :
    _codes = List.of(codes),
    _inputs = inputs.reversed.toList();

  int get pointer => _pointer;

  set pointer(int next) {
    _pointer = next != null ? checkListIndex(next, _codes.length, message: "invalid pointer: $next") : null;
  }

  int get(int i) => _codes[i];

  void set(int i, int code) => _codes[i] = code;

  int input() => _inputs.removeLast();

  void output(int value) => _outputs.add(value);

  List<int> run() {
    while (_pointer != null) {
      Instruction.parse(_codes[_pointer]).run(this);
    }
    return List.unmodifiable(_outputs);
  }

  int param(int pointer, Mode mode) {
    var value = _codes[pointer];
    if (mode == Mode.position) {
      value = _codes[value];
    }
    return value;
  }
}

class Instruction extends Equatable {

  final int _opcode;
  final List<Mode> _modes;

  Instruction(this._opcode, this._modes);

  static Instruction parse(int instructionCode) {
    checkArgument(instructionCode > 0,  message: "invalid instruction code: $instructionCode");
    final digits = instructionCode.toString().padLeft(2, "0").split("").reversed.map(int.parse).toList();
    final modes = digits.sublist(2).map((mode) => Mode.values[mode]).toList();
    return Instruction(digits[0] + 10 * digits[1], modes);
  }

  @override
  List<Object> get props => [_opcode, _modes];

  Mode mode(int param) => param < _modes.length ? _modes[param] : Mode.position;

  void run(Intcode code) {
    switch (_opcode) {
      case 1: // add
        code.set(code.get(code.pointer + 3), code.param(code.pointer + 1, mode(0)) + code.param(code.pointer + 2, mode(1)));
        code.pointer += 4;
        break;
      case 2: // multiply
        code.set(code.get(code.pointer + 3), code.param(code.pointer + 1, mode(0)) * code.param(code.pointer + 2, mode(1)));
        code.pointer += 4;
        break;
      case 3: // input
        code.set(code.get(code.pointer + 1), code.input());
        code.pointer += 2;
        break;
      case 4: // output
        code.output(code.param(code.pointer + 1, mode(0)));
        code.pointer += 2;
        break;
      case 5: // jump if true
        final value = code.param(code.pointer + 1, mode(0));
        code.pointer = value != 0 ? code.param(code.pointer + 2, mode(1)) : code.pointer + 3;
        break;
      case 6: // jump if false
        final value = code.param(code.pointer + 1, mode(0));
        code.pointer = value == 0 ? code.param(code.pointer + 2, mode(1)) : code.pointer + 3;
        break;
      case 7: // less than
        code.set(code.get(code.pointer + 3), code.param(code.pointer + 1, mode(0)) < code.param(code.pointer + 2, mode(1)) ? 1 : 0);
        code.pointer += 4;
        break;
      case 8: // equals
        code.set(code.get(code.pointer + 3), code.param(code.pointer + 1, mode(0)) == code.param(code.pointer + 2, mode(1)) ? 1 : 0);
        code.pointer += 4;
        break;
      case 99:
        code.pointer = null;
        break;
      default: throw ArgumentError("unsupported opcode: $_opcode");
    }
  }
}

enum Mode { position, immediate }
