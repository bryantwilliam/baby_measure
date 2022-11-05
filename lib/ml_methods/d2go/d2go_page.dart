import 'dart:developer';
import 'dart:io';

import 'package:baby_measure/ml_methods/d2go/recognition_model.dart';
import 'package:baby_measure/ml_methods/d2go/render_boxes.dart';
import 'package:baby_measure/ml_methods/d2go/render_keypoints.dart';
import 'package:baby_measure/ml_methods/d2go/render_segments.dart';
import 'package:baby_measure/ml_methods/rectangle_detector.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_d2go/flutter_d2go.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../main.dart';
import '../utils.dart';
import 'd2go_button.dart';

class D2GoPage extends StatefulWidget {
  final RectangleDetector rectangleDetector;
  const D2GoPage(this.rectangleDetector, {Key? key}) : super(key: key);

  @override
  State<D2GoPage> createState() => _D2GoPageState();
}

class _D2GoPageState extends State<D2GoPage> {
  List<DetectedRectangle>? _rectangleObjects;

  List<RecognitionModel>? _recognitions;
  File? _selectedImage;

  int _modelIndex = 0;

  int _imageIndex = imageNames.length -
      1; // for performance testing, click next button to go to first image.
  int? _imageWidth;
  int? _imageHeight;
  final ImagePicker _picker = ImagePicker();

  CameraController? controller;
  bool _isDetecting = false;
  bool _isLiveModeOn = false;

  @override
  void initState() {
    super.initState();
    loadModel(modelNames[0]);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    List<Widget> stackChildren = [];

    stackChildren.add(
      Positioned(
        top: 0.0,
        left: 0.0,
        width: screenWidth,
        child: _selectedImage == null
            ? Image.asset(
                'assets/images/${imageNames[_imageIndex]}',
              )
            : Image.file(_selectedImage!),
      ),
    );

    if (_isLiveModeOn) {
      stackChildren.add(
        Positioned(
          top: 0.0,
          left: 0.0,
          width: screenWidth,
          child: CameraPreview(controller!),
        ),
      );
    }

    if (_recognitions != null) {
      final aspectRatio = _imageHeight! / _imageWidth! * screenWidth;
      final widthScale = screenWidth / _imageWidth!;
      final heightScale = aspectRatio / _imageHeight!;

      if (_recognitions!.first.mask != null) {
        stackChildren.addAll(_recognitions!.map(
          (recognition) {
            return RenderSegments(
              imageWidthScale: widthScale,
              imageHeightScale: heightScale,
              recognition: recognition,
            );
          },
        ).toList());
      }

      if (_recognitions!.first.keypoints != null) {
        for (RecognitionModel recognition in _recognitions!) {
          List<Widget> keypointChildren = [];

          var keypoints = recognition.keypoints!;

          // render:
          for (Keypoint keypoint in keypoints) {
            keypointChildren.add(
              RenderKeypoints(
                keypoint: keypoint,
                imageWidthScale: widthScale,
                imageHeightScale: heightScale,
              ),
            );
          }
          stackChildren.addAll(keypointChildren);
          //

          log("###################################################################################################################################################################################");
          log("(Recognition ${recognition.detectedClass}, ${recognition.confidenceInClass}), keypoints: ${recognition.keypoints!.length}");
          log("Rectangles found: ${_rectangleObjects?.length}");
          if (_rectangleObjects != null) {
            for (var rectangleObject in _rectangleObjects!) {
              var realLifeFactor = rectangleObject.getReallifeAverageFactor();
              log("pixel rectangle width: ${rectangleObject.rect.width}");
              log("pixel rectangle height: ${rectangleObject.rect.height}");
              log("real rectangle width: ${realLifeFactor.getProductString(rectangleObject.rect.width)}");
              log("real rectangle height: ${realLifeFactor.getProductString(rectangleObject.rect.height)}");

              logDimensions(keypoints, rectangleObject, realLifeFactor);
            }
          }
        }
      }

      stackChildren.addAll(_recognitions!.map(
        (recognition) {
          return RenderBoxes(
            imageWidthScale: widthScale,
            imageHeightScale: heightScale,
            recognition: recognition,
          );
        },
      ).toList());
    }

    if (_rectangleObjects != null) {
      for (var rectangleObject in _rectangleObjects!) {
        stackChildren.add(
          rectangleObject.getRectPositioned(
            _imageWidth!.toDouble(),
            _imageHeight!.toDouble(),
            screenWidth,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter D2Go'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Image: ${imageNames[_imageIndex]}"),
          const SizedBox(height: 48),
          Expanded(
            child: Stack(
              children: stackChildren,
            ),
          ),
          D2GoButton(
            onPressed: () async {
              _modelIndex != modelNames.length - 1
                  ? _modelIndex += 1
                  : _modelIndex = 0;
              await loadModel(modelNames[_modelIndex]);
            },
            text: 'New Model\n${_modelIndex + 1}/${modelNames.length}',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                D2GoButton(
                  onPressed: () {
                    setState(
                      () {
                        _recognitions = null;
                        if (_selectedImage == null) {
                          _imageIndex != imageNames.length - 1
                              ? _imageIndex += 1
                              : _imageIndex = 0;
                        } else {
                          _selectedImage = null;
                        }
                      },
                    );
                    detectOnce();
                  },
                  text: 'Test Image\n${_imageIndex + 1}/${imageNames.length}',
                ),
                D2GoButton(
                    onPressed: () async {
                      final XFile? pickedFile =
                          await _picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile == null) return;
                      setState(
                        () {
                          _recognitions = null;
                          _selectedImage = File(pickedFile.path);
                        },
                      );
                    },
                    text: 'Select'),
                D2GoButton(
                    onPressed: () async {
                      _isLiveModeOn
                          ? await controller!.stopImageStream()
                          : await live();
                      setState(
                        () {
                          _isLiveModeOn = !_isLiveModeOn;
                          _recognitions = null;
                          _selectedImage = null;
                        },
                      );
                    },
                    text: 'Live'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void logDimensions(List<Keypoint> keypoints,
      DetectedRectangle rectangleObject, RealLifeFactorResult realLifeFactor) {
    log("(Rectangle ${rectangleObject.objIndex})");
    rectangleObject.objIndex;

    Point getPoint(int keyPointIndex) {
      var kp = keypoints[keyPointIndex];
      return Point(
        x: kp.x,
        y: kp.y,
      );
    }

    double armsSpan = Point.distOfPoints([
      getPoint(10),
      getPoint(8),
      getPoint(6),
      getPoint(5),
      getPoint(7),
      getPoint(9),
    ]);

    double headWidth = getDistance(
      getPoint(4),
      getPoint(3),
    );

    double shoulderWidth = getDistance(
      getPoint(6),
      getPoint(5),
    );

    double hipWidth = getDistance(
      getPoint(12),
      getPoint(11),
    );

    double rightLeg = Point.distOfPoints([
      getPoint(12),
      getPoint(14),
      getPoint(16),
    ]);

    double leftLeg = Point.distOfPoints([
      getPoint(11),
      getPoint(13),
      getPoint(15),
    ]);

    double averageLegLength = (rightLeg + leftLeg) / 2;

    Point middleHip = getMiddlePoint(
      getPoint(12),
      getPoint(11),
    );
    Point middleShoulder = getMiddlePoint(
      getPoint(6),
      getPoint(5),
    );
    double middleHipToMiddleShoulder = getDistance(
      middleHip,
      middleShoulder,
    );
    double middleShoulderToNose = getDistance(
      middleShoulder,
      getPoint(0),
    );
    double noseToMiddleEye = getDistance(
      getPoint(0),
      getMiddlePoint(
        getPoint(2),
        getPoint(1),
      ),
    );
    double heightToEyes = averageLegLength +
        middleHipToMiddleShoulder +
        middleShoulderToNose +
        noseToMiddleEye;

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

  Future<void> live() async {
    controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
    );
    await controller!.initialize().then(
      (_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      },
    );
    await controller!.startImageStream(
      (CameraImage cameraImage) async {
        if (_isDetecting) return;

        _isDetecting = true;

        await FlutterD2go.getStreamImagePrediction(
          imageBytesList:
              cameraImage.planes.map((plane) => plane.bytes).toList(),
          width: cameraImage.width,
          height: cameraImage.height,
          minScore: 0.5,
          rotation: 90,
        ).then(
          (predictions) {
            /*
            `rect`: scale of the original image.
            `mask` and `keypoints` depend on whether the d2go model has mask and keypoints.
            `mask` will be a `Uint8List` of bitmap images bytes. `keypoints` will be a list of 17 (x, y).

            Output Example Format:
            [
              {
                "rect": {
                  "left": 74.65713500976562,
                  "top": 76.94147491455078,
                  "right": 350.64324951171875,
                  "bottom": 323.0279846191406
                },
                "mask": [66, 77, 122, 0, 0, 0, 0, 0, 0, 0, 122, ...],
                "keypoints": [[117.14504, 77.277405], [122.74037, 73.53044], [105.95437, 73.53044], ...],
                "confidenceInClass": 0.985002338886261,
                "detectedClass": "bicycle"
              }, // For each instance
            ...
            ]
            */
            List<RecognitionModel>? recognitions;
            if (predictions.isNotEmpty) {
              recognitions = predictions.map(
                (e) {
                  return RecognitionModel(
                      Rectangle(
                        e['rect']['left'],
                        e['rect']['top'],
                        e['rect']['right'],
                        e['rect']['bottom'],
                      ),
                      e['mask'],
                      e['keypoints'] != null
                          ? (e['keypoints'] as List)
                              .map((k) => Keypoint(k[0], k[1]))
                              .toList()
                          : null,
                      e['confidenceInClass'],
                      e['detectedClass']);
                },
              ).toList();
            }
            setState(
              () {
                // With android, the inference result of the camera streaming image is tilted 90 degrees,
                // so the vertical and horizontal directions are reversed.
                _imageWidth = cameraImage.height;
                _imageHeight = cameraImage.width;
                _recognitions = recognitions;
              },
            );
          },
        ).whenComplete(
          () => Future.delayed(
            const Duration(
              milliseconds: 100,
            ),
            () {
              setState(() => _isDetecting = false);
            },
          ),
        );
      },
    );
  }

  Future<void> loadModel(String fileName) async {
    String modelPath = 'assets/models/$fileName';
    String labelPath = 'assets/models/classes.txt';
    try {
      await FlutterD2go.loadModel(
        modelPath: modelPath,
        labelPath: labelPath,
      );
      setState(() {});
    } on PlatformException {
      debugPrint('Load model or label file failed.');
    }
    detectOnce();
  }

  Future<void> detectOnce() async {
    if (_isLiveModeOn) {
      return;
    }
    final image = _selectedImage ??
        await getImageFileFromAssets('images/${imageNames[_imageIndex]}');
    final decodedImage = await decodeImageFromList(image.readAsBytesSync());
    final predictions = await FlutterD2go.getImagePrediction(
      image: image,
      minScore: 0.8,
    );

    List<RecognitionModel>? recognitions;
    if (predictions.isNotEmpty) {
      recognitions = predictions.map(
        (e) {
          return RecognitionModel(
              Rectangle(
                e['rect']['left'],
                e['rect']['top'],
                e['rect']['right'],
                e['rect']['bottom'],
              ),
              e['mask'],
              e['keypoints'] != null
                  ? (e['keypoints'] as List)
                      .map((k) => Keypoint(k[0], k[1]))
                      .toList()
                  : null,
              e['confidenceInClass'],
              e['detectedClass']);
        },
      ).toList();
    }

    var rectangleObjects =
        await widget.rectangleDetector.getDetectedRectangles(image);

    setState(
      () {
        _imageWidth = decodedImage.width;
        _imageHeight = decodedImage.height;
        _recognitions = recognitions;
        _rectangleObjects = rectangleObjects;
      },
    );
  }
}
