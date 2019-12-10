import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:quiver/check.dart';
import 'package:test/test.dart';

void main() {

  group("Day 9", () {

    test("relative mode", () {
      expect(Intcode([109, 5, 204, 0, 99, 42], []).run(), [42]);
    });

    test("random memory", () {
      expect(Intcode([3, 100, 4, 100, 99, 0], [42]).run(), [42]);
    });

    test("copy self", () {
      const codes = [109, 1, 204, -1, 1001, 100, 1, 100, 1008, 100, 16, 101, 1006, 101, 0, 99];
      expect(Intcode(codes, []).run(), codes);
    });

    test("output a 16-digit number", () {
      const codes = [1102, 34915192, 34915192, 7, 4, 7, 99, 0];
      expect(Intcode(codes, []).run(), [1219070632396864]);
    });

    test("output a large number", () {
      const codes = [104, 1125899906842624, 99];
      expect(Intcode(codes, []).run(), [codes[1]]);
    });

    List<int> input() => File("data/09.txt")
      .readAsStringSync()
      .split(",")
      .map(int.parse)
      .toList();

    test("Part 1", () {
      expect(Intcode(input(), [1]).run(), [3497884671]);
    });

    test("Part 2", () {
      expect(Intcode(input(), [2]).run(), [46470]);
    });
  });
}

class Intcode {

  final Map<int, int> _codes = {};
  final List<int> _inputs;
  final List<int> _outputs = [];
  var _pointer = 0;
  var base = 0;

  Intcode(List<int> codes, List<int> inputs) : _inputs = inputs.reversed.toList() {
    for (var i = 0; i < codes.length; ++i) {
      _codes[i] = codes[i];
    }
  }

  int get pointer => _pointer;

  set pointer(int next) => _pointer = next;

  int get(int i) {
    checkArgument(i >= 0, message: "must not be negative: $i");
    return _codes[i] ?? 0;
  }

  void set(int i, int code) {
    checkArgument(i >= 0, message: "must not be negative: $i");
    _codes[i] = code;
  }

  int input() => _inputs.removeLast();

  void output(int value) => _outputs.add(value);

  List<int> run() {
    while (_pointer != null) {
      Instruction.parse(get(_pointer)).run(this);
    }
    return List.unmodifiable(_outputs);
  }

  int runStep(int input) {
    _inputs.insert(0, input);
    _outputs.clear();
    while (_pointer != null && _outputs.isEmpty) {
      Instruction.parse(get(_pointer)).run(this);
    }
    return _outputs.isNotEmpty ? _outputs.last : null;
  }

  int getPointer(int offset, Mode mode) {
    var value = get(pointer + offset);
    if (mode == Mode.relative) {
      value += base;
    }
    return value;
  }

  int param(int offset, Mode mode) {
    var value = get(pointer + offset);
    if (mode == Mode.position) {
      value = get(value);
    } else if (mode == Mode.relative) {
      value = get(value + base);
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
        code.set(code.getPointer(3, mode(2)), code.param(1, mode(0)) + code.param(2, mode(1)));
        code.pointer += 4;
        break;
      case 2: // multiply
        code.set(code.getPointer(3, mode(2)), code.param(1, mode(0)) * code.param(2, mode(1)));
        code.pointer += 4;
        break;
      case 3: // input
        code.set(code.getPointer(1, mode(0)), code.input());
        code.pointer += 2;
        break;
      case 4: // output
        code.output(code.param(1, mode(0)));
        code.pointer += 2;
        break;
      case 5: // jump if true
        final value = code.param(1, mode(0));
        code.pointer = value != 0 ? code.param(2, mode(1)) : code.pointer + 3;
        break;
      case 6: // jump if false
        final value = code.param(1, mode(0));
        code.pointer = value == 0 ? code.param(2, mode(1)) : code.pointer + 3;
        break;
      case 7: // less than
        code.set(code.getPointer(3, mode(2)), code.param(1, mode(0)) < code.param(2, mode(1)) ? 1 : 0);
        code.pointer += 4;
        break;
      case 8: // equals
        code.set(code.getPointer(3, mode(2)), code.param(1, mode(0)) == code.param(2, mode(1)) ? 1 : 0);
        code.pointer += 4;
        break;
      case 9: // adjust relative base
        code.base += code.param(1, mode(0));
        code.pointer += 2;
        break;
      case 99:
        code.pointer = null;
        break;
      default: throw ArgumentError("unsupported opcode: $_opcode");
    }
  }
}

enum Mode { position, immediate, relative }
