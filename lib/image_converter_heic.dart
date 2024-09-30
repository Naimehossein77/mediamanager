import 'package:flutter/services.dart';

class ImageConverter {
  // Private constructor
  ImageConverter._privateConstructor();

  // Static private instance variable
  static final ImageConverter _instance = ImageConverter._privateConstructor();

  // Factory constructor to return the instance
  static ImageConverter get instance => _instance;

  // Method channel instance
  static const MethodChannel _platform = MethodChannel('imageconverter');

  // Method to convert HEIC to JPEG
  Future<String> convertHeicToJpg(String filePath) async {
    try {
      final String result = await _platform.invokeMethod('convertHeicToJpg', filePath);
      return result;
    } on PlatformException catch (e) {
      throw 'Failed to convert HEIC to JPEG: ${e.message}';
    }
  }
}
