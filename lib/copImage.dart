import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart'; // For cache directory

Future<File?> cropFaceAndSaveToCache(
    AssetEntity asset, Rect boundingBox) async {
  // Load the image from AssetEntity as Uint8List
  Uint8List? originalImageData = await asset.originBytes;

  if (originalImageData != null) {
    // Decode the image using the image package
    img.Image? originalImage = img.decodeImage(originalImageData);

    if (originalImage != null) {
      // Convert bounding box from Rect to integer-based rectangle for cropping
      int x = boundingBox.left.toInt();
      int y = boundingBox.top.toInt();
      int width = boundingBox.width.toInt();
      int height = boundingBox.height.toInt();

      // Ensure the bounding box is within the image dimensions
      if (x + width > originalImage.width) {
        width = originalImage.width - x;
      }
      if (y + height > originalImage.height) {
        height = originalImage.height - y;
      }

      // Crop the image to the bounding box
      img.Image croppedImage =
          img.copyCrop(originalImage, x: x, y: y, width: width, height: height);

      // Encode the cropped image back to Uint8List
      Uint8List croppedImageData =
          Uint8List.fromList(img.encodeJpg(croppedImage));

      // Save cropped image to a cache file
      String filePath = await _saveCroppedImageToCache(croppedImageData);

      return File(filePath); // Return the file in cache
    }
  }
  return null;
}

// Helper function to save Uint8List image as a file in cache directory
Future<String> _saveCroppedImageToCache(Uint8List imageData) async {
  // Get cache directory
  Directory cacheDir =
      await getTemporaryDirectory(); // Or getCacheDir for persistent cache

  // Create a file path for the cached image
  String filePath =
      '${cacheDir.path}/cropped_face_${DateTime.now().millisecondsSinceEpoch}.jpg';

  // Write the image data to the file
  File file = File(filePath);
  await file.writeAsBytes(imageData);

  return filePath;
}
