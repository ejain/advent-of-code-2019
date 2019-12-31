import 'package:equatable/equatable.dart';
import 'package:test/test.dart';

void main() {

  group("Day 12", () {

    test("apply gravity and velocity to a moon", () {

      var moon = Moon(Vector(1, 2, 3));
      expect(moon, Moon(Vector(1, 2, 3), Vector(0, 0, 0)));

      moon = moon.applyGravity(Vector(-1, 2, 4));
      expect(moon, Moon(Vector(1, 2, 3), Vector(-1, 0, 1)));

      moon = moon.applyVelocity();
      expect(moon, Moon(Vector(0, 2, 4), Vector(-1, 0, 1)));
    });

    test("calculate a moon's energy", () {

      expect(Moon(Vector(0, -1, 2), Vector(3, -4, 5)).energy(), 36);
    });

    test("simulate steps", () {

      var system = System([
        Moon(Vector(-1, 0, 2)),
        Moon(Vector(2, -10, -7)),
        Moon(Vector(4, -8, 8)),
        Moon(Vector(3, 5, -1)),
      ]);

      system = system.simulate(steps: 1);
      expect(system.moons[0], Moon(Vector(2, -1, 1), Vector(3, -1, -1)));
      expect(system.moons[1], Moon(Vector(3, -7, -4), Vector(1, 3, 3)));
      expect(system.moons[2], Moon(Vector(1, -7, 5), Vector(-3, 1, -3)));
      expect(system.moons[3], Moon(Vector(2, 2, 0), Vector(-1, -3, 1)));

      system = system.simulate(steps: 9);
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
      expect(input().simulate(steps: 1000).energy(), 7988);
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

  final Vector _position;
  final Vector _velocity;

  Moon(this._position, [ this._velocity = const Vector(0, 0, 0) ]);

  Vector get position => _position;

  Vector get velocity => _position;

  Moon applyGravity(Vector position) {
    return Moon(_position, _velocity.add(Vector(
      (position.x - _position.x).sign,
      (position.y - _position.y).sign,
      (position.z - _position.z).sign
    )));
  }

  Moon applyVelocity() {
    return Moon(_position.add(_velocity), _velocity);
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

  System simulate({int steps = 1}) {
    var system = this;
    for (var step = 0; step < steps; ++step) {
      system = system._simulate();
    }
    return system;
  }

  System _simulate() => System(moons.map((moon) {
    return moons.where((other) => !identical(other, moon))
      .fold(moon, (Moon moon, Moon other) => moon.applyGravity(other._position))
      .applyVelocity();
  }));

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

  final int _position;
  final int _velocity;

  Moon1D(this._position, [ this._velocity = 0 ]);

  Moon1D applyGravity(int position) => Moon1D(_position, _velocity + (position - _position).sign);

  Moon1D applyVelocity() => Moon1D(_position + _velocity, _velocity);

  @override
  List<Object> get props => [_position, _velocity];

  @override
  String toString() => "{position:$_position, velocity:$_velocity}";
}

class System1D extends Equatable {

  final List<Moon1D> moons;

  System1D(Iterable<Moon1D> moons) : moons = List.unmodifiable(moons);

  System1D _simulate() => System1D(moons.map((moon) {
    return moons.where((other) => !identical(other, moon))
      .fold(moon, (Moon1D moon, Moon1D other) => moon.applyGravity(other._position))
      .applyVelocity();
  }));

  int findCycleLength() {
    const maxSteps = 1000000000000;
    var system = System1D([
      for (var moon in moons)
        Moon1D(moon._position, moon._velocity)
    ]);
    for (var step = 1; step <= maxSteps; ++step) {
      system = system._simulate();
      if (system == this) {
        return step;
      }
    }
    throw StateError("no cycles within $maxSteps steps");
  }

  @override
  List<Object> get props => [moons];
}
