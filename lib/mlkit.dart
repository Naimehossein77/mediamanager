import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorManager {
  static final FaceDetectorManager _instance = FaceDetectorManager._privateConstructor();
  late final FaceDetector _faceDetector;

  // Private constructor
  FaceDetectorManager._privateConstructor() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.3
      )
    );
  }

  // Singleton instance accessor
  static FaceDetectorManager get instance => _instance;

  // Method to process image and detect faces
  Future<List<Face>> detectFaces(File imageFile) async {
    final InputImage inputImage = InputImage.fromFile(imageFile);
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    return faces;
  }

  // Properly close the face detector
  void dispose() {
    _faceDetector.close();
  }
}
