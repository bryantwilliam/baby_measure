import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_d2go/flutter_d2go.dart';
import 'package:path_provider/path_provider.dart';

import 'ml_method.dart';

class D2GoMethod implements MLMethod {
  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('assets/$path');

    final file = await File('${(await getTemporaryDirectory()).path}/$path')
        .create(recursive: true);
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  @override
  Future<void> run() async {
    await FlutterD2go.loadModel(
      modelPath: 'assets/models/d2go.ptl',
      labelPath: 'assets/models/classes.txt',
    );

    var image = await getImageFileFromAssets('images/input1.jpg');

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

    // arguments are the default as of version 0.6.0
    var output = await FlutterD2go.getImagePrediction(
      image: image,
      inputWidth: 320,
      inputHeight: 320,
      mean: [0.0, 0.0, 0.0],
      std: [1.0, 1.0, 1.0],
      minScore: 0.5,
    );

    print("D2Go output: $output");
  }
}
