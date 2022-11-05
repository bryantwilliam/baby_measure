import 'dart:developer';
import 'dart:io';

import 'package:baby_measure/ml_methods/rectangle_detector.dart';
import 'package:baby_measure/ml_methods/google_pose/pose_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:ui' as ui;
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
            key: const ValueKey('process_google_button'),
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

    setState(() {
      _stackChildren = [Image.file(imageFile)];
    });

    ui.Image decodedImage =
        await decodeImageFromList(imageFile.readAsBytesSync());

    var detectedRectangles =
        await widget.rectangleDetector.getDetectedRectangles(imageFile);

    var poses = await poseDetector.processImage(inputImage);

    renderRectangles(detectedRectangles, decodedImage, screenWidth);
    renderPoses(poses, decodedImage, screenWidth);

    log("Poses found: ${poses.length}\n\n");

    int poseIndex = 0;
    for (Pose pose in poses) {
      poseIndex++;
      log("###################################################################################################################################################################################");
      log("(Pose $poseIndex), landmarks: ${pose.landmarks.length}");

      for (var rectangle in detectedRectangles) {
        log("----------------------------------------------------------------------------------------");
        log("(Rectangle ${rectangle.objIndex})");

        var realLifeFactor = rectangle.getReallifeAverageFactor();
        log("pixel rectangle width: ${rectangle.rect.width}");
        log("pixel rectangle height: ${rectangle.rect.height}");
        log("real rectangle width: ${realLifeFactor.getProductString(rectangle.rect.width)}");
        log("real rectangle height: ${realLifeFactor.getProductString(rectangle.rect.height)}");

        log("*************With Z...");
        logDimensions(pose, realLifeFactor, true);
        log("*************Without Z...");
        logDimensions(pose, realLifeFactor, false);
      }
    }
  }

  logDimensions(Pose pose, RealLifeFactorResult realLifeFactor, bool withZ) {
    Point getLMPoint(PoseLandmarkType lmType) {
      PoseLandmark lm = pose.landmarks[lmType]!;
      return Point(
        x: lm.x,
        y: lm.y,
        z: withZ ? lm.z : 0,
      );
    }

    double distOfLMs(List<PoseLandmarkType> lmTypes) {
      List<Point> points = [];

      for (var lmType in lmTypes) {
        points.add(getLMPoint(lmType));
      }

      return Point.distOfPoints(points);
    }

    double armsSpan = distOfLMs([
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

    double shoulderWidth = distOfLMs([
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftShoulder,
    ]);

    double hipWidth = distOfLMs([
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftHip,
    ]);

    double rightLeg = distOfLMs([
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
      PoseLandmarkType.rightHeel,
    ]);

    double leftLeg = distOfLMs([
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.leftHeel,
    ]);

    double averageLegLength = (rightLeg + leftLeg) / 2;

    Point middleHip = getMiddlePoint(
      getLMPoint(PoseLandmarkType.rightHip),
      getLMPoint(PoseLandmarkType.leftHip),
    );

    Point middleShoulder = getMiddlePoint(
      getLMPoint(PoseLandmarkType.rightShoulder),
      getLMPoint(PoseLandmarkType.leftShoulder),
    );

    double middleHipToMiddleShoulder = getDistance(
      middleHip,
      middleShoulder,
    );

    Point middleMouth = getMiddlePoint(
      getLMPoint(PoseLandmarkType.rightMouth),
      getLMPoint(PoseLandmarkType.leftMouth),
    );

    double middleShoulderToMiddleMouth = getDistance(
      middleShoulder,
      middleMouth,
    );

    double middleMouthToMiddleEye = getDistance(
      middleMouth,
      getMiddlePoint(
        getLMPoint(PoseLandmarkType.rightEyeInner),
        getLMPoint(PoseLandmarkType.leftEyeInner),
      ),
    );
    double heightToEyes = averageLegLength +
        middleHipToMiddleShoulder +
        middleShoulderToMiddleMouth +
        middleMouthToMiddleEye;

    // Arm Span, Head Width, Shoulder Width, Hip Width, HeightToEyes

    log("Pixel Arms Span: $armsSpan");
    log("Pixel Head Width: $headWidth");
    log("Pixel Shoulder Width: $shoulderWidth");
    log("Pixel Hip Width: $hipWidth");
    log("Pixel Height to eyes: $heightToEyes");

    log("Real Arms Span: ${realLifeFactor.getProductString(armsSpan)}");
    log("Real Head Width: ${realLifeFactor.getProductString(headWidth)}");
    log("Real Shoulder Width: ${realLifeFactor.getProductString(shoulderWidth)}");
    log("Real Hip Width: ${realLifeFactor.getProductString(hipWidth)}");
    log("Real Height to eyes: ${realLifeFactor.getProductString(heightToEyes)}");
  }

  void renderRectangles(List<DetectedRectangle> detectedRectangles,
      ui.Image decodedImage, double screenWidth) {
    log("Rectangles Found: ${detectedRectangles.length}");

    for (var rectangleObject in detectedRectangles) {
      setState(() {
        _stackChildren.add(rectangleObject.getRectPositioned(
            decodedImage.width.toDouble(),
            decodedImage.height.toDouble(),
            screenWidth));
      });
    }
  }

  void renderPoses(
      List<Pose> poses, ui.Image decodedImage, double screenWidth) {
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
