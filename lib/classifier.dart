import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart';

class MoveNetClassifier {
  late Interpreter _interpreter;
  late ImageProcessor imageProcessor;
  late TensorImage inputImage;
  late List<Object> inputs;

  Map<int, Object> outputs = {};
  TensorBuffer outputLocations = TensorBufferFloat([]);

  MoveNetClassifier() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        "movenet.tflite",
        options: InterpreterOptions()..threads = 4,
      );
      outputLocations = TensorBufferFloat([1, 1, 17, 3]);
    } catch (e) {
      debugPrint("Error while creating interpreter: $e");
    }
  }

  TensorImage _getProcessedImage() {
    int padSize = max(inputImage.height, inputImage.width);
    imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(192, 192, ResizeMethod.bilinear))
        .build();

    return imageProcessor.process(inputImage);
  }

  Future<void> processImage(image_lib.Image image) async {
    inputImage = TensorImage.fromImage(image); // Load the image
    inputImage = _getProcessedImage(); // Process the image
    inputs = [inputImage.buffer]; // Prepare inputs
  }

  Future<void> runModel() async {
    outputs = {0: outputLocations.buffer};
    _interpreter.runForMultipleInputs(inputs, outputs);
  }

  List parseLandmarkData() {
    List<double> data = outputLocations.getDoubleList();
    List result = [];
    int x, y;
    double confidence;

    for (var i = 0; i < 51; i += 3) {
      y = (data[i] * 480).toInt(); // Adjust for your display height
      x = (data[i + 1] * 640).toInt(); // Adjust for your display width
      confidence = data[i + 2];
      result.add([x, y, confidence]);
    }

    return result;
  }

  void dispose() {
    _interpreter.close();
  }
}
