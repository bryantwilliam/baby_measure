import 'dart:math';
import 'dart:typed_data';

class RecognitionModel {
  RecognitionModel(
    this.rect,
    this.mask,
    this.keypoints,
    this.confidenceInClass,
    this.detectedClass,
  );
  Rectangle rect;
  Uint8List? mask;
  List<Keypoint>? keypoints;
  double confidenceInClass;
  String detectedClass;
}

class Rectangle {
  Rectangle(this.left, this.top, this.right, this.bottom);
  double left;
  double top;
  double right;
  double bottom;
}

class Keypoint {
  Keypoint(this.x, this.y);
  double x;
  double y;
}
