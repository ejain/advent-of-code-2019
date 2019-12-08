import 'dart:io';

import 'package:quiver/check.dart';
import 'package:test/test.dart';

void main() {

  group("Day 8", () {

    Image input() => Image.parse(25, 6, File("data/08.txt").readAsStringSync().trim());

    test("parse an image", () {
      final image = Image.parse(3, 2, "123456789012");
      expect(image.layers, hasLength(2));
      expect(image.layers[0].get(0, 0), 1);
      expect(image.layers[0].get(1, 0), 2);
      expect(image.layers[0].get(2, 0), 3);
      expect(image.layers[0].get(0, 1), 4);
      expect(image.layers[0].get(1, 1), 5);
      expect(image.layers[0].get(2, 1), 6);
      expect(image.layers[1].get(0, 0), 7);
      expect(image.layers[1].get(1, 0), 8);
      expect(image.layers[1].get(2, 0), 9);
      expect(image.layers[1].get(0, 1), 0);
      expect(image.layers[1].get(1, 1), 1);
      expect(image.layers[1].get(2, 1), 2);
      expect(() => image.layers[0].get(3, 0), throwsRangeError);
      expect(() => image.layers[0].get(0, 2), throwsRangeError);
    });

    test("Part 1", () {
      final layer = input().layers.reduce((left, right) {
        return left.count(0) < right.count(0) ? left : right;
      });
      expect(layer.count(1) * layer.count(2), 2125);
    });

    test("decode an image", () {
      final image = Image.parse(2, 2, "0222112222120000");
      expect(image.toString(),
        " █\n"
        "█ \n"
      );
    });

    test("Part 2", () {
      expect(input().toString(),
        "  ██ █   █████ █  █ ████ \n"
        "   █ █   █   █ █  █ █    \n"
        "   █  █ █   █  ████ ███  \n"
        "   █   █   █   █  █ █    \n"
        "█  █   █  █    █  █ █    \n"
        " ██    █  ████ █  █ █    \n"
      );
    });
  });
}

class Image {

  final int width, height;
  final List<Layer> layers = [];

  Image(this.width, this.height, List<int> data) {
    checkArgument(data.length % (width * height) == 0, message: "invalid dimensions");
    final layerSize = width * height;
    final numLayers = data.length ~/ layerSize;
    for (var i = 0; i < numLayers; ++i) {
      layers.add(Layer(width, height, data.sublist(i * layerSize, (i + 1) * layerSize)));
    }
  }

  Image.parse(int width, int height, String s) :
    this(width, height, s.split("").map(int.parse).toList());

  int get(int x, int y) {
    checkListIndex(x, width, message: "invalid x: $x");
    checkListIndex(y, height, message: "invalid y: $y");
    for (var layer in layers) {
      final value = layer.get(x, y);
      if (value != 2) {
        return value;
      }
    }
    return null;
  }

  @override
  String toString() {
    var s = StringBuffer();
    for (var y = 0; y < height; ++y) {
      for (var x = 0; x < width; ++x) {
        final value = get(x, y);
        s.write(value != 0 ? "█" : " ");
      }
      s.writeln();
    }
    return s.toString();
  }
}

class Layer {

  final int _width, _height;
  final List<int> _data;

  Layer(this._width, this._height, this._data);

  int count(int value) => _data.where((n) => n == value).length;

  int get(int x, int y) {
    checkListIndex(x, _width, message: "invalid x: $x");
    checkListIndex(y, _height, message: "invalid y: $y");
    return _data[x + y * _width];
  }
}
