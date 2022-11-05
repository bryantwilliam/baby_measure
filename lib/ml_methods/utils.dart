import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<File> getImageFileFromAssets(String path) async {
  final byteData = await rootBundle.load('assets/$path');

  final file = await File('${(await getTemporaryDirectory()).path}/$path')
      .create(recursive: true);
  await file.writeAsBytes(byteData.buffer
      .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

  return file;
}

double getDistance(Point point1, Point point2) {
  // d = sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)

  return sqrt(pow(point2.x - point1.x, 2) +
      pow(point2.y - point1.y, 2) +
      pow(point2.z - point1.z, 2));
}

Point getMiddlePoint(Point point1, Point point2) {
  // x,y,z = (x1 + x2)/2, (y1+y2)/2, (z1+z2)/2

  return Point(
    x: (point1.x + point2.x) / 2,
    y: (point1.y + point2.y) / 2,
    z: (point1.z + point2.z) / 2,
  );
}

class Point {
  double x;
  double y;
  double z;

  Point({
    required this.x,
    required this.y,
    this.z = 0,
  });

  static double distOfPoints(List<Point> points) {
    return points.fold<double>(0, (previousValue, point) {
      int nextIndex = points.indexOf(point) + 1;
      if (nextIndex < points.length) {
        var nextPoint = points.elementAt(nextIndex);
        return previousValue +
            getDistance(
              point,
              nextPoint,
            );
      }

      return previousValue;
    });
  }
}
