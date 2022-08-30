import 'package:baby_measure/ml_methods/d2go/recognition_model.dart';
import 'package:flutter/material.dart';

class RenderSegments extends StatelessWidget {
  const RenderSegments({
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
    final mask = recognition.mask!;
    return Positioned(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
      child: Image.memory(
        mask,
        fit: BoxFit.fill,
      ),
    );
  }
}
