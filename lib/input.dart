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
  List<List<Map<String, dynamic>>> _keypoints = [];
  // List<List<double>> _keypoints = [];

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
    _moveNetClassifier ??= MoveNetClassifier();

    // Load the model if it's not loaded already
    await _moveNetClassifier.loadModel();

    // Process the image and run the model
    await _moveNetClassifier.processAndRunModel(image); // Pass the image file

    // Extract keypoints from the processed output
    List<List<Map<String, dynamic>>> keypoints = await _moveNetClassifier.keypoints;

    // Update UI with the extracted keypoints
    setState(() {
      _keypoints = keypoints; // _keypoints is a List<List<Map<String, dynamic>>>
    });

    print("Keypoints: $_keypoints"); // Check the extracted keypoints in the console
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
                  // if (_keypoints.isNotEmpty)
                  //   Positioned.fill(
                  //     child: KeypointOverlay(
                  //         keypoints:
                  //             _keypoints), // Ensure _keypoints is List<List<double>>
                  //   ),
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

