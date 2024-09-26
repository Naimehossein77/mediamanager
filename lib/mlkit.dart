import 'dart:io';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

Future<void> detectFaces(File imageFile) async {
  final InputImage inputImage = InputImage.fromFile(imageFile);
  final faceDetector = FaceDetector(options: FaceDetectorOptions());

  // Process the image to detect faces
  final List<Face> faces = await faceDetector.processImage(inputImage);
  print("Number of faces detected: ${faces.length}");

  for (Face face in faces) {
    final Rect boundingBox = face.boundingBox;
    print("Face found at: ${boundingBox.left}, ${boundingBox.top}");
  }
  
  faceDetector.close();
}
