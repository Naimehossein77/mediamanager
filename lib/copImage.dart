import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

Future<File> cropImage(File imageFile, Face face) async {
  img.Image originalImage = img.decodeImage(await imageFile.readAsBytes())!;
  img.Image croppedImage = img.copyCrop(originalImage,
      x: face.boundingBox.left.toInt(),
      y: face.boundingBox.top.toInt(),
      width: face.boundingBox.width.toInt(),
      height: face.boundingBox.height.toInt());
  return await saveCroppedImage(croppedImage);
}


Future<File> saveCroppedImage(img.Image croppedImage) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = directory.path;
  final file = File('$path/cropped_image.png');
  file.writeAsBytesSync(img.encodePng(croppedImage));
  return file;
}
