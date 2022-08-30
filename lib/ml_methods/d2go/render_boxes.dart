import 'package:baby_measure/ml_methods/d2go/recognition_model.dart';
import 'package:flutter/material.dart';

class RenderBoxes extends StatelessWidget {
  const RenderBoxes({
    Key? key,
    required this.recognition,
    required this.imageWidthScale,
    required this.imageHeightScale,
  }) : super(key: key);

  final RecognitionModel recognition;
  final double imageWidthScale;
  final double imageHeightScale;

  @override
  Widget build(BuildContext context) {
    final left = recognition.rect.left * imageWidthScale;
    final top = recognition.rect.top * imageHeightScale;
    final right = recognition.rect.right * imageWidthScale;
    final bottom = recognition.rect.bottom * imageHeightScale;
    return Positioned(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          border: Border.all(
            color: Colors.yellow,
            width: 2,
          ),
        ),
        child: Text(
          "${recognition.detectedClass} ${(recognition.confidenceInClass * 100).toStringAsFixed(0)}%",
          style: TextStyle(
            background: Paint()..color = Colors.yellow,
            color: Colors.black,
            fontSize: 15.0,
          ),
        ),
      ),
    );
  }
}
