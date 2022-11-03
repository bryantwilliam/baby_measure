import 'dart:developer';
import 'dart:io';

import 'package:baby_measure/ml_methods/credit_card_detector.dart';
import 'package:baby_measure/ml_methods/google_pose/pose_painter.dart';
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
  List<Widget> _stackChildren = [];
  int _imageIndex = 3;

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
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              setState(() {
                if (_imageIndex >= imageNames.length - 1) {
                  _imageIndex = 0;
                } else {
                  _imageIndex++;
                }
              });
              await process(screenWidth);
            },
            child: Text("Next Image"),
          ),
          ElevatedButton(
            onPressed: () async {
              await process(screenWidth);
            },
            child: Text("Process test image"),
          ),
          Expanded(
            child: Stack(
              children: _stackChildren,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> process(double screenWidth) async {
    File imageFile =
        await getImageFileFromAssets('images/${imageNames[_imageIndex]}');
    final inputImage = InputImage.fromFile(
      imageFile,
    );

    final List<Pose> poses = await poseDetector.processImage(inputImage);

    var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());

    // NOTICE render the pose in this page
    // https://pub.dev/packages/google_mlkit_pose_detection
    // https://developers.google.com/ml-kit/vision/pose-detection
    // example: https://github.com/bharat-biradar/Google-Ml-Kit-plugin/blob/master/packages/google_ml_kit/example/lib/vision_detector_views/pose_detector_view.dart
    // example 2 with render: https://github.com/bhaskar2728/MLKit-Pose-Detection-CameraX-With-Video-Recording
    // painter example: https://github.com/salkuadrat/learning/blob/master/packages/learning_pose_detection/lib/src/painter.dart
    // painter example 2: https://pub.dev/packages/body_detection

    log("Poses found: ${poses.length}\n\n");

    int poseIndex = 0;
    for (Pose pose in poses) {
      poseIndex++;
      // to access all landmarks
      pose.landmarks.forEach((_, landmark) {
        final type = landmark.type;
        final liklihood = landmark.likelihood;
        final x = landmark.x;
        final y = landmark.y;
        final z = landmark.z;
      });
      log("(pose $poseIndex), landmarks: ${pose.landmarks.length}");

      // to access specific landmarks
      final landmark = pose.landmarks[PoseLandmarkType.leftEar];
    }

    //

    var detectedCreditCards =
        await widget.creditCardDetector.getDetectedCreditCards(imageFile);

    var image = Image.file(imageFile);

    setState(() {
      _stackChildren = [image];
    });

    if (detectedCreditCards.isNotEmpty) {
      log("image contains cards");
    }
    for (var card in detectedCreditCards) {
      // TODO calculate real-life pose dimensions from credit card.
      card.rect;
      DetectedCreditCard.CREDIT_CARD_HEIGHT_MM;
      DetectedCreditCard.CREDIT_CARD_WIDTH_MM;

      setState(() {
        _stackChildren.add(card.getRectPositioned(decodedImage.width.toDouble(),
            decodedImage.height.toDouble(), screenWidth));
      });
    }

    final PosePainter painter = PosePainter(
      poses,
      Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      ),
    );

    final aspectRatio = decodedImage.height / decodedImage.width * screenWidth;
    final widthScale = screenWidth / decodedImage.width;
    final heightScale = aspectRatio / decodedImage.height;

    setState(() {
      _stackChildren.add(
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(
              color: Color.fromARGB(255, 7, 214, 241),
              width: 2,
            ),
          ),
          child: CustomPaint(
            painter: painter,
            size: Size(
              decodedImage.width.toDouble() * widthScale,
              decodedImage.height.toDouble() * heightScale,
            ),
          ),
        ),
      );
    });
  }
}
