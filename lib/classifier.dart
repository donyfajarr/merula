import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart';

class MoveNetClassifier {
  Interpreter? _interpreter; // Interpreter can be null until initialized
  late ImageProcessor imageProcessor;
  late TensorImage inputImage;
  late List<Object> inputs;
  List<List<int>>? _outputShapes;

  Map<int, Object> outputs = {};
  TensorBuffer outputLocations = TensorBufferFloat([]);

  Future<void> loadModel({Interpreter? interpreter}) async {
    try {
      print("Load Model");
      // Check if the interpreter is already initialized
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            "movenet.tflite",
            options: InterpreterOptions()..threads = 4,
          );
      final outputTensors = _interpreter?.getOutputTensors();
      _outputShapes = [];
      outputTensors?.forEach((tensor) {
        _outputShapes?.add(tensor.shape);
      });
      outputLocations = TensorBufferFloat([1, 1, 17, 3]);
      print("Model successfully loaded.");
    } catch (e) {
      debugPrint("Error while creating interpreter: $e");
      throw Exception("Failed to load the interpreter.");
    }
  }

  bool isInterpreterInitialized() {
    return _interpreter != null;
  }

  TensorImage _getProcessedImage() {
    int padSize = max(inputImage.height, inputImage.width);
    imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(256, 256, ResizeMethod.bilinear))
        .build();

    return imageProcessor.process(inputImage);
  }

  Future<void> processImage(image_lib.Image image) async {
    if (!isInterpreterInitialized()) {
      throw Exception("Interpreter not initialized.");
    }
    print('Masuk ke function');
    inputImage = TensorImage.fromImage(image); // Load the image
    print('Masuk ke function 2');
    inputImage = _getProcessedImage(); // Process the image
    inputs = [inputImage.buffer]; // Prepare inputs
  }

  Future<void> runModel() async {
    if (!isInterpreterInitialized()) {
      throw Exception("Interpreter not initialized.");
    }
    outputs = {0: outputLocations.buffer};
    _interpreter!.runForMultipleInputs(inputs, outputs);
  }

  List parseLandmarkData() {
    List<double> data = outputLocations.getDoubleList();
    const Map<String, int> KEYPOINT_DICT = {
      'nose': 0,
      'left_eye': 1,
      'right_eye': 2,
      'left_ear': 3,
      'right_ear': 4,
      'left_shoulder': 5,
      'right_shoulder': 6,
      'left_elbow': 7,
      'right_elbow': 8,
      'left_wrist': 9,
      'right_wrist': 10,
      'left_hip': 11,
      'right_hip': 12,
      'left_knee': 13,
      'right_knee': 14,
      'left_ankle': 15,
      'right_ankle': 16
    };

    List result = [];
    double x, y;
    double confidence;
    // print(data[0]);
    for (var i = 0; i < 51; i += 3) {
      y = (data[i] * 256); // Adjust for your display height
      x = (data[i + 1] * 256); // Adjust for your display width
      confidence = data[i + 2];

      result.add([x, y, confidence]);
    }

    return result;
  }

  void dispose() {
    _interpreter?.close();
  }
}
