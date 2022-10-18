import 'dart:io';

import 'package:baby_measure/ml_methods/credit_card_detector.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';

import '../../main.dart';
import '../utils.dart';

// NOTICE: This doesn't work on iOS. To make it work later, I can follow requirements here: https://github.com/bharat-biradar/Google-Ml-Kit-plugin
class GooglePosePage extends StatefulWidget {
  final CreditCardDetector creditCardDetector;
  const GooglePosePage(this.creditCardDetector, {Key? key}) : super(key: key);

  @override
  State<GooglePosePage> createState() => _GooglePosePageState();
}

class _GooglePosePageState extends State<GooglePosePage> {
  late final PoseDetector poseDetector;
  final CreditCardDetector _googleObjectDetector = CreditCardDetector();

  @override
  void initState() {
    final options = PoseDetectorOptions();
    poseDetector = PoseDetector(options: options);
    super.initState();
  }

  @override
  void dispose() {
    poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              await processImage();
            },
            child: Text("Process test image"),
          ),
        ],
      ),
    );
  }

  Future<void> processImage() async {
    File imageFile = await getImageFileFromAssets('images/${imageNames[1]}');
    final inputImage = InputImage.fromFile(
      imageFile,
    );
    final List<Pose> poses = await poseDetector.processImage(inputImage);

    // NOTICE render the pose in this page
    // https://pub.dev/packages/google_mlkit_pose_detection
    // https://developers.google.com/ml-kit/vision/pose-detection
    // example: https://github.com/bharat-biradar/Google-Ml-Kit-plugin/blob/master/packages/google_ml_kit/example/lib/vision_detector_views/pose_detector_view.dart
    // example 2 with render: https://github.com/bhaskar2728/MLKit-Pose-Detection-CameraX-With-Video-Recording
    // painter example: https://github.com/salkuadrat/learning/blob/master/packages/learning_pose_detection/lib/src/painter.dart
    // painter example 2: https://pub.dev/packages/body_detection

    for (Pose pose in poses) {
      // to access all landmarks
      pose.landmarks.forEach((_, landmark) {
        final type = landmark.type;

        final x = landmark.x;
        final y = landmark.y;
      });

      // to access specific landmarks
      final landmark = pose.landmarks[PoseLandmarkType.leftEar];
    }

    var detectedCreditCards =
        await widget.creditCardDetector.getDetectedCreditCards(imageFile);
    for (var card in detectedCreditCards) {
      // NOTICE render the card paint layer on this page as well (can add the render layers in a stack)...
      card.paintLayer;

      // TODO calculate real-life pose dimensions from credit card.
      card.rect;
      DetectedCreditCard.CREDIT_CARD_HEIGHT_MM;
      DetectedCreditCard.CREDIT_CARD_WIDTH_MM;
    }
  }
}
