import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../main.dart';
import 'utils.dart';

class RectangleDetector {
  final _detector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    ),
  );

  Future<List<DetectedRectangle>> getDetectedRectangles(File imageFile) async {
    final List<DetectedObject> objects =
        await _detector.processImage(InputImage.fromFile(imageFile));

    final List<DetectedRectangle> detectedRectangles = [];

    int objectIndex = 0;
    for (DetectedObject detectedObject in objects) {
      final rect = detectedObject.boundingBox;
      final trackingId = detectedObject.trackingId;

      objectIndex++;
      int labelIndex = 0;
      Label? firstLabel;
      if (detectedObject.labels.isEmpty) {
        log("object $objectIndex has no labels");
      } else {
        firstLabel = detectedObject.labels[0];
      }

      detectedRectangles.add(
        DetectedRectangle(
          rect: rect,
          label: firstLabel,
          objIndex: objectIndex,
        ),
      );
    }
    return detectedRectangles;
  }

  void close() {
    _detector.close();
  }
}

class RealLifeFactorResult {
  late final double _value;
  late final double _plusMinus;

  RealLifeFactorResult(double value, double plusMinus) {
    _value = value;
    _plusMinus = plusMinus;
  }

  get value => _value;
  get plusMinus => _plusMinus;

  String getProductString(double num) {
    return "${value * num} +/-${plusMinus * num}";
  }
}

class DetectedRectangle {
  static const int _REAL_RECTOBJ_WIDTH = 210;
  static const int _REAL_RECTOBJ_HEIGHT = 297;
  final Rect rect;
  final Label? label;
  final int objIndex;

  DetectedRectangle({
    required this.rect,
    required this.label,
    required this.objIndex,
  });

  RealLifeFactorResult getReallifeAverageFactor() {
    double heightFactor = DetectedRectangle._REAL_RECTOBJ_HEIGHT / rect.height;
    double widthFactor = DetectedRectangle._REAL_RECTOBJ_WIDTH / rect.width;

    return RealLifeFactorResult(
        (widthFactor + heightFactor) / 2,
        (math.max(heightFactor, widthFactor) -
                math.min(heightFactor, widthFactor)) /
            2);
  }

  Positioned getRectPositioned(
      double imageWidth, double imageHeight, double screenWidth) {
    final aspectRatio = imageHeight / imageWidth * screenWidth;
    final widthScale = screenWidth / imageWidth;
    final heightScale = aspectRatio / imageHeight;

    final left = rect.left * widthScale;
    final top = rect.top * heightScale;
    final right = rect.right * widthScale;
    final bottom = rect.bottom * heightScale;
    return Positioned(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          border: Border.all(
            color: Color.fromARGB(255, 9, 255, 0),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              "<$objIndex>",
              style: TextStyle(color: Colors.indigo),
            ),
            ...(label != null
                ? [
                    Text(
                      label != null ? label!.text.toString() : "no label",
                      style: TextStyle(color: Colors.red),
                    ),
                    Text(
                      label != null ? label!.confidence.toString() : "no label",
                      style: TextStyle(color: Colors.green),
                    ),
                  ]
                : [
                    Text(
                      "No Label",
                      style: TextStyle(color: Colors.red),
                    )
                  ]),
          ],
        ),
      ),
    );
  }
}
