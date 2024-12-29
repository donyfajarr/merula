import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'dart:io';

// import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart';

class MoveNetClassifier {
  Interpreter? _interpreter; // Interpreter can be null until initialized
  // late ImageProcessor imageProcessor;
  // late TensorImage inputImage;
  late List<Object> inputs;
  List<List<int>>? _outputShapes;
  late Map<int, Object> outputs;
  late List<double> _outputBuffer;
  List<List<Map<String, dynamic>>> keypoints = [];

  // Map<int, Object> outputs = {};
  // TensorBuffer outputLocations = TensorBufferFloat([]);

  Future<void> loadModel({Interpreter? interpreter}) async {
    try {
      print("Load Model");
      // Check if the interpreter is already initialized
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            "assets/movenet.tflite",
            options: InterpreterOptions()..threads = 4,
          );
      final outputTensors = _interpreter?.getOutputTensors();
      _outputShapes = [];
      outputTensors?.forEach((tensor) {
        _outputShapes?.add(tensor.shape);
      });
      // outputLocations = TensorBufferFloat([1, 1, 17, 3]);
      print("Model successfully loaded.");
    } catch (e) {
      debugPrint("Error while creating interpreter: $e");
      throw Exception("Failed to load the interpreter.");
    }
  }

  bool isInterpreterInitialized() {
    return _interpreter != null;
  }

  Future<Uint8List> preprocessImage(Uint8List imageBytes, List<int> inputShape) async {
    // Decode the image
    image_lib.Image? image = image_lib.decodeImage(imageBytes);
    if (image == null) {
      throw Exception("Failed to decode image.");
    }

    // Resize the image to the model's input size (typically 256x256)
    image = image_lib.copyResize(image, width: 256, height: 256);

    // Convert to the format expected by the model
    List<int> imageAsList = image.getBytes();
    return Uint8List.fromList(imageAsList);
  }

  // Run the model
  Future<void> processAndRunModel(File imageFile) async {
    if (_interpreter == null) {
      print("Model is not loaded.");
      return;
    }

    try {
      print("Processing image...");

      // Load and preprocess the image
      Uint8List imageBytes = await imageFile.readAsBytes();
      List<int> inputShape = _interpreter!.getInputTensor(0).shape;
      Uint8List processedImage = await preprocessImage(imageBytes, inputShape);

      // Prepare inputs for the model
      inputs = [processedImage];

      // Prepare output buffer
      outputs = {0: List.filled(_interpreter!.getOutputTensor(0).shape.reduce((a, b) => a * b), 0.0)};
      
      // Run the model
      _interpreter!.runForMultipleInputs(inputs, outputs);

      // Get the output tensor
      List<List<List<List<double>>>> outputData = outputs[0] as List<List<List<List<double>>>>;

      // Extract keypoints and confidence scores
      keypoints.clear();
      for (int i = 0; i < 17; i++) {
        double y = outputData[0][0][i][0];  // y-coordinate (normalized)
        double x = outputData[0][0][i][1];  // x-coordinate (normalized)
        double confidence = outputData[0][0][i][2];  // confidence score

        keypoints.add([
          {"keypoint": i, "y": y, "x": x, "confidence": confidence}
        ]);
      }
      
      // Print the keypoints and their confidence scores
      keypoints.forEach((keypoint) {
        print("Keypoint ${keypoint[0]['keypoint']}: y=${keypoint[0]['y']}, x=${keypoint[0]['x']}, confidence=${keypoint[0]['confidence']}");
      });
      

    } catch (e) {
      print("Error running model: $e");
    }
  }
  
  void dispose() {
    _interpreter?.close();
  }
}
