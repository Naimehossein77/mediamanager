import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; // Import TFLite Flutter
import 'package:image/image.dart' as img;

class FaceRecognitionService {
  static late Interpreter _interpreter;

  // Load the TFLite model
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
      print('Model loaded successfully ${_interpreter.isAllocated}');
      print('Model input shape: ${_interpreter.getInputTensor(0).shape}');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  // Function to get face embeddings
  Future<List<List<double>>> getFaceEmbeddings(File image) async {
    // Preprocess the image if necessary (resize, normalize, etc.)
    // Load image as a tensor
    final img = await preprocessImageWithBatch(image);

    // Run the model
    var output = List.filled(
        1,
        List.filled(
            192, 0.0)); // Adjust the size according to your model's output

    if (_interpreter.isAllocated) _interpreter.run(img, output);

    return output;
  }

  // Compare two face embeddings
  // bool compareEmbeddings(List<double> embedding1, List<double> embedding2) {
  //   // Calculate Euclidean distance
  //   double distance = 0.0;

  //   for (int i = 0; i < embedding1.length; i++) {
  //     distance +=
  //         (embedding1[i] - embedding2[i]) * (embedding1[i] - embedding2[i]);
  //   }
  //   distance = cosineSimilarity(distance);
  //   print(distance);
  //   // Set a threshold for comparison
  //   return distance < 0.4; // Adjust this threshold based on your testing
  // }

  Future<List<List<List<List<double>>>>> preprocessImageWithBatch(
      File imageFile) async {
    // Load the image
    img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) {
      throw Exception('Unable to decode image');
    }

    // Resize the image to the expected input size (e.g., 224x224 for MobileNet)
    img.Image resizedImage = img.copyResize(image, width: 112, height: 112);

    // Normalize the pixel values between -1 and 1 (for MobileNet or similar models)
    List<List<List<double>>> normalizedImage = [];

    for (int y = 0; y < resizedImage.height; y++) {
      List<List<double>> row = [];
      for (int x = 0; x < resizedImage.width; x++) {
        var pixel = resizedImage.getPixel(x, y);

        // Convert ARGB to RGB and normalize (assuming a 0-255 pixel range)
        double r = ((pixel.r.toInt() >> 16) & 0xFF) / 127.5 - 1.0;
        double g = ((pixel.g.toInt() >> 8) & 0xFF) / 127.5 - 1.0;
        double b = (pixel.b.toInt() & 0xFF) / 127.5 - 1.0;

        row.add([r, g, b]);
      }
      normalizedImage.add(row);
    }

    // Add batch dimension to make it [1, height, width, channels]
    return [
      normalizedImage
    ]; // Wrapping it in a list to add the batch dimension
  }

// Function to calculate cosine similarity
  bool cosineSimilarity(List<double> embedding1, List<double> embedding2) {
    double dotProduct = 0.0;
    double normEmbedding1 = 0.0;
    double normEmbedding2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      normEmbedding1 += pow(embedding1[i], 2);
      normEmbedding2 += pow(embedding2[i], 2);
      
    }

    double similarity =
        dotProduct / (sqrt(normEmbedding1) * sqrt(normEmbedding2));
    print(similarity);

    return similarity > .90;
  }
}
