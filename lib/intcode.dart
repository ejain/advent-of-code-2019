import 'package:equatable/equatable.dart';
import 'package:quiver/check.dart';

class Intcode {

  final Map<int, int> _codes = {};
  final List<int> _inputs;
  final List<int> _outputs = [];
  int pointer = 0;
  int base = 0;

  Intcode(List<int> codes, List<int> inputs) : _inputs = inputs.reversed.toList() {
    for (var i = 0; i < codes.length; ++i) {
      _codes[i] = codes[i];
    }
  }

  Intcode copy() {
    final copy = Intcode([], []);
    copy._codes.addAll(_codes);
    copy._inputs.addAll(_inputs);
    copy._outputs.addAll(_outputs);
    copy.pointer = pointer;
    copy.base = base;
    return copy;
  }

  int get(int i) {
    checkArgument(i >= 0, message: "must not be negative: $i");
    return _codes[i] ?? 0;
  }

  void set(int i, int code) {
    checkArgument(i >= 0, message: "must not be negative: $i");
    _codes[i] = code;
  }

  int input() {
    if (_inputs.isEmpty) {
      throw MissingInputException();
    }
    return _inputs.removeLast();
  }

  void output(int value) => _outputs.add(value);

  void addInput(int input) => _inputs.insert(0, input);

  List<int> run() {
    try {
      while (pointer != null) {
        Instruction.parse(get(pointer)).run(this);
      }
    } on MissingInputException {

    }
    return _drain();
  }

  int next() {
    try {
      while (pointer != null && _outputs.isEmpty) {
        Instruction.parse(get(pointer)).run(this);
      }
    } on MissingInputException {

    }
    final outputs = _drain();
    checkState(outputs.length <= 1, message: "expected a single output");
    return outputs.isNotEmpty ? outputs.first : null;
  }

  List<int> _drain() {
    final outputs = List.of(_outputs);
    _outputs.clear();
    return outputs;
  }

  bool get isTerminated => pointer == null;
}

class Instruction extends Equatable {

  final int _opcode;
  final List<Mode> _modes;

  Instruction(this._opcode, this._modes);

  static Instruction parse(int instructionCode) {
    checkArgument(instructionCode > 0,  message: "invalid instruction code: $instructionCode");
    final digits = instructionCode.toString().padLeft(2, "0").split("").reversed.map(int.parse).toList();
    final modes = digits.sublist(2).map((mode) => Mode.of(mode)).toList();
    return Instruction(digits[0] + 10 * digits[1], modes);
  }

  @override
  List<Object> get props => [_opcode, _modes];

  Mode _mode(int param) => param < _modes.length ? _modes[param] : const PositionMode();

  void run(Intcode code) {

    int get(int offset) => _mode(offset - 1).param(code, offset);
    void set(int offset, int value) => code.set(_mode(offset - 1).pointer(code, offset), value);

    switch (_opcode) {
      case 1: // add
        set(3, get(1) + get(2));
        code.pointer += 4;
        break;
      case 2: // multiply
        set(3, get(1) * get(2));
        code.pointer += 4;
        break;
      case 3: // input
        set(1, code.input());
        code.pointer += 2;
        break;
      case 4: // output
        code.output(get(1));
        code.pointer += 2;
        break;
      case 5: // jump if true
        code.pointer = get(1) != 0 ? get(2) : code.pointer + 3;
        break;
      case 6: // jump if false
        code.pointer = get(1) == 0 ? get(2) : code.pointer + 3;
        break;
      case 7: // less than
        set(3, get(1) < get(2) ? 1 : 0);
        code.pointer += 4;
        break;
      case 8: // equals
        set(3, get(1) == get(2) ? 1 : 0);
        code.pointer += 4;
        break;
      case 9: // adjust relative base
        code.base += get(1);
        code.pointer += 2;
        break;
      case 99:
        code.pointer = null;
        break;
      default: throw ArgumentError("unsupported opcode: $_opcode");
    }
  }
}

class MissingInputException implements Exception {

}

abstract class Mode {

  const Mode();

  factory Mode.of(int mode) {
    switch(mode) {
      case 0: return const PositionMode();
      case 1: return const ImmediateMode();
      case 2: return const RelativeMode();
      default: throw ArgumentError("unsupported mode: $mode");
    }
  }

  int param(Intcode code, int offset) => code.get(pointer(code, offset));

  int pointer(Intcode code, int offset);
}

class PositionMode extends Mode {

  const PositionMode() : super();

  @override
  int pointer(Intcode code, int offset) => code.get(code.pointer + offset);
}

class ImmediateMode extends Mode {

  const ImmediateMode() : super();

  @override
  int pointer(Intcode code, int offset) => code.pointer + offset;
}

class RelativeMode extends Mode {

  const RelativeMode() : super();

  @override
  int param(Intcode code, int offset) => code.get(pointer(code, offset));

  @override
  int pointer(Intcode code, int offset) => code.get(code.pointer + offset) + code.base;
}
