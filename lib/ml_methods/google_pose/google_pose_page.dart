import 'dart:developer';
import 'dart:io';

import 'package:baby_measure/ml_methods/rectangle_detector.dart';
import 'package:baby_measure/ml_methods/google_pose/pose_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';

import '../../main.dart';
import '../utils.dart';

// NOTICE: This doesn't work on iOS. To make it work later, I can follow requirements here: https://github.com/bharat-biradar/Google-Ml-Kit-plugin
class GooglePosePage extends StatefulWidget {
  final RectangleDetector rectangleDetector;
  const GooglePosePage(this.rectangleDetector, {Key? key}) : super(key: key);

  @override
  State<GooglePosePage> createState() => _GooglePosePageState();
}

class _GooglePosePageState extends State<GooglePosePage> {
  late final PoseDetector poseDetector;
  final RectangleDetector _googleObjectDetector = RectangleDetector();
  List<Widget> _stackChildren = [];
  int _imageIndex = 0;

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
          Text("Image: ${imageNames[_imageIndex]}"),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    if (_imageIndex <= 0) {
                      _imageIndex = imageNames.length - 1;
                    } else {
                      _imageIndex--;
                    }
                  });
                  await process(screenWidth);
                },
                child: Text("Previous Image"),
              ),
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
            ],
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

    var detectedRectangles =
        await widget.rectangleDetector.getDetectedRectangles(imageFile);

    var image = Image.file(imageFile);

    setState(() {
      _stackChildren = [image];
    });

    if (detectedRectangles.isNotEmpty) {
      log("image contains rectangle objects");
    }
    for (var rectangleObject in detectedRectangles) {
      // TODO calculate real-life pose dimensions from detected rectangle objects.
      double realLifeFactor = rectangleObject.getReallifeAverageFactor();

      Point getLMPoint(PoseLandmarkType lmType) {
        PoseLandmark lm = poses.first.landmarks[lmType]!;
        return Point(
          x: lm.x,
          y: lm.y,
          z: lm.z,
        );
      }

      double distOfLMs(List<PoseLandmarkType> lmTypes) {
        return lmTypes.fold<double>(0, (previousValue, lmType) {
          int nextIndex = lmTypes.indexOf(lmType) + 1;
          if (nextIndex < lmTypes.length) {
            var nextLmType = lmTypes.elementAt(lmTypes.indexOf(lmType) - 1);
            return previousValue +
                getDistance(
                  getLMPoint(lmType),
                  getLMPoint(nextLmType),
                );
          }

          return previousValue;
        });
      }

      double armsSpam = distOfLMs([
        PoseLandmarkType.rightPinky,
        PoseLandmarkType.rightWrist,
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist,
        PoseLandmarkType.leftPinky,
      ]);

      double headWidth = distOfLMs([
        PoseLandmarkType.rightEar,
        PoseLandmarkType.leftEar,
      ]);

      double shoulderWidth = getDistance(
        getLMPoint(PoseLandmarkType.rightShoulder),
        getLMPoint(PoseLandmarkType.leftShoulder),
      );

      double hipWidth = getDistance(
        getLMPoint(PoseLandmarkType.rightHip),
        getLMPoint(PoseLandmarkType.leftHip),
      );

      double averageLegLength = (distOfLMs([]) + distOfLMs([])) / 2;
      double middleHipToMiddleShoulder = getDistance(
        getMiddlePoint(
          getLMPoint(PoseLandmarkType.rightHip),
          getLMPoint(PoseLandmarkType.leftHip),
        ),
        getMiddlePoint(
          getLMPoint(PoseLandmarkType.rightShoulder),
          getLMPoint(PoseLandmarkType.leftShoulder),
        ),
      );

      double middleShoulderToMiddleMouth = 0;
      double middleMouthToMiddleEye = 0;
      double heightToEyes = averageLegLength +
          middleHipToMiddleShoulder +
          middleShoulderToMiddleMouth +
          middleMouthToMiddleEye;

      // TODO: finish calculation and print out:
      // Arm Span, Head Width, Shoulder Width, Hip Width, HeightToEyes

      poses.first.landmarks[PoseLandmarkType.rightPinky];

      setState(() {
        _stackChildren.add(rectangleObject.getRectPositioned(
            decodedImage.width.toDouble(),
            decodedImage.height.toDouble(),
            screenWidth));
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
