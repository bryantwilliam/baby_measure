import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';

import '../../main.dart';
import '../utils.dart';

// NOTICE: This doesn't work on iOS. To make it work later, I can follow requirements here: https://github.com/bharat-biradar/Google-Ml-Kit-plugin
class GoogleMLToolkitPage extends StatefulWidget {
  const GoogleMLToolkitPage({Key? key}) : super(key: key);

  @override
  State<GoogleMLToolkitPage> createState() => _GoogleMLToolkitPageState();
}

class _GoogleMLToolkitPageState extends State<GoogleMLToolkitPage> {
  late final PoseDetector poseDetector;

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
    // TODO: Using the camera plugin, can change this to camera later: https://github.com/bharat-biradar/Google-Ml-Kit-plugin/tree/master/packages/google_mlkit_commons#creating-an-inputimage
    final inputImage = InputImage.fromFile(
      await getImageFileFromAssets('images/${imageNames[1]}'),
    );
    final List<Pose> poses = await poseDetector.processImage(inputImage);

    // TODO render it in this page
    // https://pub.dev/packages/google_mlkit_pose_detection
    // https://developers.google.com/ml-kit/vision/pose-detection
    // example: https://github.com/bharat-biradar/Google-Ml-Kit-plugin/tree/master/packages/google_ml_kit/example

    for (Pose pose in poses) {
      // to access all landmarks
      pose.landmarks.forEach((_, landmark) {
        final type = landmark.type;
        final x = landmark.x;
        final y = landmark.y;
      });

      // to access specific landmarks
      final landmark = pose.landmarks[PoseLandmarkType.nose];
    }
  }
}
