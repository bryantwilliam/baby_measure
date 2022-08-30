import 'package:baby_measure/ml_methods/d2go/recognition_model.dart';
import 'package:flutter/material.dart';

class RenderKeypoints extends StatelessWidget {
  const RenderKeypoints({
    Key? key,
    required this.keypoint,
    required this.imageWidthScale,
    required this.imageHeightScale,
  }) : super(key: key);

  final Keypoint keypoint;
  final double imageWidthScale;
  final double imageHeightScale;

  @override
  Widget build(BuildContext context) {
    final x = keypoint.x * imageWidthScale;
    final y = keypoint.y * imageHeightScale;
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
