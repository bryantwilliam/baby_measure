import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../main.dart';
import 'utils.dart';

class CreditCardDetector {
  final _detector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    ),
  );

  Future<List<DetectedCreditCard>> getDetectedCreditCards(
      File imageFile) async {
    final List<DetectedObject> objects =
        await _detector.processImage(InputImage.fromFile(imageFile));

    final List<DetectedCreditCard> detectedCreditCards = [];

    for (DetectedObject detectedObject in objects) {
      final rect = detectedObject.boundingBox;
      final trackingId = detectedObject.trackingId;

      for (Label label in detectedObject.labels) {
        print('${label.text} ${label.confidence}');
      }

      /* TODO: check if credit card and then add it to the list.
      if (is a credit card) {
        // example: https://github.com/bharat-biradar/Google-Ml-Kit-plugin/blob/master/packages/google_ml_kit/example/lib/vision_detector_views/object_detector_view.dart
        // NOTICE: put a paintlayer widget for the credit card here.
        creditCards.add(DetectedCreditCard(rect, paintLayer));
      }*/
    }
    return detectedCreditCards;
  }

  void close() {
    _detector.close();
  }
}

class DetectedCreditCard {
  static const double CREDIT_CARD_WIDTH_MM = 85.6;
  static const double CREDIT_CARD_HEIGHT_MM = 53.98;
  Rect rect;
  final Placeholder paintLayer; // NOTICE can change to a widget later

  DetectedCreditCard({
    required this.rect,
    required this.paintLayer,
  });
}
