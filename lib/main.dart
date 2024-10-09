import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as image_lib;
import 'classifier.dart'; // Import your classifier

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Picker and MoveNet',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ImagePickerScreen(),
    );
  }
}

class ImagePickerScreen extends StatefulWidget {
  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  late MoveNetClassifier _moveNetClassifier;

  @override
  void initState() {
    super.initState();
    _moveNetClassifier = MoveNetClassifier();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _processImage(_image!);
    }
  }

  Future<void> _processImage(File image) async {
    final imageBytes = await image.readAsBytes();
    image_lib.Image? originalImage = image_lib.decodeImage(imageBytes);
    if (originalImage != null) {
      await _moveNetClassifier.processImage(originalImage);
      await _moveNetClassifier.runModel();

      List landmarks = _moveNetClassifier.parseLandmarkData();
      print(landmarks); // Use the landmarks for further processing
      // You can also update the UI to show landmarks here if needed
    }
  }

  @override
  void dispose() {
    _moveNetClassifier.dispose();
    super.dispose();
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
            _image == null ? Text('No image selected.') : Image.file(_image!),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
          ],
        ),
      ),
    );
  }
}
