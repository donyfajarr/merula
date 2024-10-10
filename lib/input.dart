import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as image_lib;
import 'classifier.dart'; // Import your classifier
import 'keypoint_overlay.dart';


class ImagePickerScreen extends StatefulWidget {
  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  late MoveNetClassifier _moveNetClassifier;
  bool _isModelReady = false; // New state to track model loading
  List<List<double>> _keypoints = [];

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
  }

  Future<void> _initializeClassifier() async {
    _moveNetClassifier = MoveNetClassifier();
    try {
      print("Loading model...");
      await _moveNetClassifier.loadModel(); // Wait until the model is loaded
      setState(() {
        _isModelReady = _moveNetClassifier
            .isInterpreterInitialized(); // Ensure interpreter is initialized
      });
      if (_isModelReady) {
        print("Model is ready for use.");
      } else {
        print("Model initialization failed.");
      }
    } catch (e) {
      print("Error initializing model: $e");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && _isModelReady) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _processImage(_image!);
    } else if (!_isModelReady) {
      print("Model is not yet ready!");
    } else {
      print("No image selected.");
    }
  }

  Future<void> _processImage(File image) async {
    if (!_isModelReady) {
      print("Model is not ready.");
      return;
    }

    final imageBytes = await image.readAsBytes();
    image_lib.Image? originalImage = image_lib.decodeImage(imageBytes);

    if (originalImage != null) {
      try {
        print("Processing image...");
        await _moveNetClassifier.processImage(originalImage);
        await _moveNetClassifier.runModel();

        // Assuming parseLandmarkData returns List<List<dynamic>>
        List<List<dynamic>> landmarks =
            _moveNetClassifier.parseLandmarkData().cast<List<dynamic>>();

        // Convert to List<List<double>> by ensuring each element is cast to double
        List<List<double>> keypoints = landmarks.map<List<double>>((landmark) {
          return [
            (landmark[0] as num).toDouble(), // x coordinate
            (landmark[1] as num).toDouble(), // y coordinate
            (landmark[2] as num).toDouble() // confidence score
          ];
        }).toList();

        setState(() {
          _keypoints =
              keypoints; // This now matches the List<List<double>> type
        });

        print(_keypoints); // Check the keypoints in the console
      } catch (e) {
        print("Error running model: $e");
      }
    } else {
      print("Failed to decode image.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Picker and MoveNet'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image == null)
              Text('No image selected.')
            else
              Stack(
                children: [
                  Container(
                    width: 256,
                    height: 256,
                    child: Image.file(_image!, fit: BoxFit.scaleDown),
                  ),
                  if (_keypoints.isNotEmpty)
                    Positioned.fill(
                      child: KeypointOverlay(
                          keypoints:
                              _keypoints), // Ensure _keypoints is List<List<double>>
                    ),
                ],
              ),
            SizedBox(height: 20),
            _isModelReady
                ? ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('Pick Image'),
                  )
                : CircularProgressIndicator(), // Show loading indicator while model loads
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _moveNetClassifier.dispose();
    super.dispose();
  }
}

