import 'dart:ui';
import 'package:flutter/material.dart';

// Define the mapping for keypoint edges and their colors
const List<List<int>> KEYPOINT_EDGE_INDS = [
  [0, 1], // Nose to left_eye
  [0, 2], // Nose to right_eye
  [1, 3], // left_eye to left_ear
  [2, 4], // right_eye to right_ear
  [0, 5], // Nose to left_shoulder
  [0, 6], // Nose to right_shoulder
  [5, 7], // left_shoulder to left_elbow
  [7, 9], // left_elbow to left_wrist
  [6, 8], // right_shoulder to right_elbow
  [8, 10], // right_elbow to right_wrist
  [5, 6], // left_shoulder to right_shoulder
  [5, 11], // left_shoulder to left_hip
  [6, 12], // right_shoulder to right_hip
  [11, 12], // left_hip to right_hip
  [11, 13], // left_hip to left_knee
  [13, 15], // left_knee to left_ankle
  [12, 14], // right_hip to right_knee
  [14, 16], // right_knee to right_ankle
];

const Map<List<int>, Color> KEYPOINT_EDGE_COLORS = {
  [0, 1]: Colors.pink,
  [0, 2]: Colors.cyan,
  [1, 3]: Colors.pink,
  [2, 4]: Colors.cyan,
  [0, 5]: Colors.pink,
  [0, 6]: Colors.cyan,
  [5, 7]: Colors.pink,
  [7, 9]: Colors.pink,
  [6, 8]: Colors.cyan,
  [8, 10]: Colors.cyan,
  [5, 6]: Colors.yellow,
  [5, 11]: Colors.pink,
  [6, 12]: Colors.cyan,
  [11, 12]: Colors.yellow,
  [11, 13]: Colors.pink,
  [13, 15]: Colors.pink,
  [12, 14]: Colors.cyan,
  [14, 16]: Colors.cyan,
};

class KeypointsPainter extends CustomPainter {
  final List<List<double>> keypoints; // [[x, y, confidence], ...]

  KeypointsPainter(this.keypoints);

  @override
  void paint(Canvas canvas, Size size) {
    final keypointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill; // Changed to fill for visibility

    // Drawing keypoints
    for (var i = 0; i < keypoints.length; i++) {
      final keypoint = keypoints[i];
      if (keypoint.length >= 2) {
        final x = keypoint[0]; // Scale x coordinate
        final y = keypoint[1]; // Scale y coordinate
        print('x adlaah');
        print(x);
        canvas.drawCircle(
            Offset(x, y), 3.0, keypointPaint); // Draw each keypoint
      }
    }

    // Draw edges based on defined edges and their colors
    for (var edge in KEYPOINT_EDGE_INDS) {
      int startIdx = edge[0];
      int endIdx = edge[1];

      // Ensure valid indices
      if (startIdx < keypoints.length && endIdx < keypoints.length) {
        final p1 = Offset(keypoints[startIdx][0], keypoints[startIdx][1]);
        final p2 = Offset(keypoints[endIdx][0], keypoints[endIdx][1]);

        final edgePaint = Paint()
          ..color = KEYPOINT_EDGE_COLORS[edge]!
          ..strokeWidth = 2.0;

        canvas.drawLine(p1, p2, edgePaint); // Draw the edge
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true; // Trigger repaint when the keypoints change
  }
}
