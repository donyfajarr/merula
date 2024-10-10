import 'package:flutter/material.dart';
import 'keypoints_painter.dart';

class KeypointOverlay extends StatelessWidget {
  final List<List<double>> keypoints; // Input keypoints to draw

  KeypointOverlay({required this.keypoints});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: KeypointsPainter(keypoints),
      child: Container(),
    );
  }
}
