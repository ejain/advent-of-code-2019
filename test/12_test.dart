import 'package:equatable/equatable.dart';
import 'package:test/test.dart';

void main() {

  group("Day 12", () {

    test("apply gravity and velocity to a moon", () {

      final moon = Moon(Vector(1, 2, 3));
      expect(moon, Moon(Vector(1, 2, 3), Vector(0, 0, 0)));

      moon.applyGravity(Vector(-1, 2, 4));
      expect(moon, Moon(Vector(1, 2, 3), Vector(-1, 0, 1)));

      moon.applyVelocity();
      expect(moon, Moon(Vector(0, 2, 4), Vector(-1, 0, 1)));
    });

    test("calculate a moon's energy", () {

      expect(Moon(Vector(0, -1, 2), Vector(3, -4, 5)).energy(), 36);
    });

    test("simulate steps", () {

      final system = System([
        Moon(Vector(-1, 0, 2)),
        Moon(Vector(2, -10, -7)),
        Moon(Vector(4, -8, 8)),
        Moon(Vector(3, 5, -1)),
      ]);

      system.simulate(steps: 1);
      expect(system.moons[0], Moon(Vector(2, -1, 1), Vector(3, -1, -1)));
      expect(system.moons[1], Moon(Vector(3, -7, -4), Vector(1, 3, 3)));
      expect(system.moons[2], Moon(Vector(1, -7, 5), Vector(-3, 1, -3)));
      expect(system.moons[3], Moon(Vector(2, 2, 0), Vector(-1, -3, 1)));

      system.simulate(steps: 9);
      expect(system.moons[0], Moon(Vector(2, 1, -3), Vector(-3, -2, 1)));
      expect(system.moons[1], Moon(Vector(1, -8, 0), Vector(-1, 1, 3)));
      expect(system.moons[2], Moon(Vector(3, -6, 1), Vector(3, 2, -3)));
      expect(system.moons[3], Moon(Vector(2, 0, 4), Vector(1, -1, -1)));
      expect(system.energy(), 179);
    });

    System input() => System([
      Moon(Vector(-1, -4, 0)),
      Moon(Vector(4, 7, -1)),
      Moon(Vector(-14, -10, 9)),
      Moon(Vector(1, 2, 17)),
    ]);

    test("Part 1", () {
      final system = input();
      system.simulate(steps: 1000);
      expect(system.energy(), 7988);
    });

    test("find the least common multiple", () {
      expect(0.lcm(42), 0);
      expect(42.lcm(42), 42);
      expect(3.lcm(4), 12);
    });

    test("find the cycle length", () {
      expect(System([
        Moon(Vector(-1, 0, 2)),
        Moon(Vector(2, -10, -7)),
        Moon(Vector(4, -8, 8)),
        Moon(Vector(3, 5, -1)),
      ]).findCycleLength(), 2772);
    });

    test("Part 2", () {
      expect(input().findCycleLength(), 337721412394184);
    });
  });
}

extension LeastCommonMultiple on int {

  int lcm(int other) => this * other ~/ gcd(other);
}

class Vector extends Equatable {

  final int x;
  final int y;
  final int z;

  const Vector(this.x, this.y, this.z);

  Vector add(Vector that) => Vector(x + that.x, y + that.y, z + that.z);

  int sum() => x.abs() + y.abs() + z.abs();

  @override
  List<Object> get props => [x, y, z];

  @override
  String toString() => "($x, $y, $z)";
}

class Moon extends Equatable {

  Vector _position;
  Vector _velocity;

  Moon(this._position, [ this._velocity = const Vector(0, 0, 0) ]);

  Vector get position => _position;

  Vector get velocity => _position;

  void applyGravity(Vector position) {
    _velocity = _velocity.add(Vector(
      (position.x - _position.x).sign,
      (position.y - _position.y).sign,
      (position.z - _position.z).sign
    ));
  }

  void applyVelocity() {
    _position = _position.add(_velocity);
  }

  int energy() => _position.sum() * _velocity.sum();

  @override
  List<Object> get props => [_position, _velocity];

  @override
  String toString() => "{position:$_position, velocity:$_velocity}";
}

class System extends Equatable {

  final List<Moon> moons;

  System(Iterable<Moon> moons) : moons = List.unmodifiable(moons);

  void simulate({int steps = 1}) {
    for (var step = 0; step < steps; ++step) {
      for (var a in moons) {
        for (var b in moons) {
          if (!identical(a, b)) {
            a.applyGravity(b.position);
          }
        }
      }
      for (var moon in moons) {
        moon.applyVelocity();
      }
    }
  }

  int energy() => moons.fold(0, (energy, moon) => energy + moon.energy());

  int findCycleLength() => _decompose()
    .map((system) => system.findCycleLength())
    .reduce((a, b) => a.lcm(b));

  Iterable<System1D> _decompose() sync* {
    yield System1D(moons.map((moon) => Moon1D(moon.position.x)));
    yield System1D(moons.map((moon) => Moon1D(moon.position.y)));
    yield System1D(moons.map((moon) => Moon1D(moon.position.z)));
  }

  @override
  List<Object> get props => [moons];
}

class Moon1D extends Equatable {

  int _position;
  int _velocity;

  Moon1D(this._position, [ this._velocity = 0 ]);

  void applyGravity(int position) {
    _velocity += (position - _position).sign;
  }

  void applyVelocity() {
    _position += _velocity;
  }

  @override
  List<Object> get props => [_position, _velocity];

  @override
  String toString() => "{position:$_position, velocity:$_velocity}";
}

class System1D extends Equatable {

  final List<Moon1D> moons;

  System1D(Iterable<Moon1D> moons) : moons = List.unmodifiable(moons);

  void _simulate({int steps = 1}) {
    for (var step = 0; step < steps; ++step) {
      for (var a in moons) {
        for (var b in moons) {
          if (!identical(a, b)) {
            a.applyGravity(b._position);
          }
        }
      }
      for (var moon in moons) {
        moon.applyVelocity();
      }
    }
  }

  int findCycleLength() {
    const maxSteps = 1000000000000;
    final system = System1D([
      for (var moon in moons)
        Moon1D(moon._position, moon._velocity)
    ]);
    for (var step = 1; step <= maxSteps; ++step) {
      system._simulate(steps: 1);
      if (system == this) {
        return step;
      }
    }
    return 0;
  }

  @override
  List<Object> get props => [moons];
}
