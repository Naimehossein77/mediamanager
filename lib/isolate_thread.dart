import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mediamanager/media.dart';
import 'package:mediamanager/sqflite.dart';
import 'package:photo_manager/photo_manager.dart';

import 'copImage.dart';
import 'image_converter_heic.dart';
import 'mlkit.dart';
import 'tflite.dart';
import 'package:path/path.dart';

// This is the entry point for the isolate
// void aiBackgroundTask(SendPort mainSendPort) {
//   // Create a port for receiving messages from the main thread
//   ReceivePort isolateReceivePort = ReceivePort();

//   // Notify any listeners on the main thread what port this isolate listens to.
//   mainSendPort.send(isolateReceivePort.sendPort);

//   // Listening for incoming messages
//   isolateReceivePort.listen((message) {
//     // Check if the message contains a command to initialize AI
//     print(message);
//     if (message[0] == 'initializeAI') {
//       var result = initializeAI(); // Your AI initialization function
//       SendPort replyTo = message[1];
//       replyTo.send(result); // Send the result back to the main thread
//     }
//   });
// }

// Example function that might take significant time or resources
initializeAI() async {
  DatabaseHelper dbHelper = DatabaseHelper();
  await FaceRecognitionService().loadModel();
  List<AssetEntity> imageList = [];
  for (int i = 0; i < 10; i++) {
    imageList.clear();
    imageList = await fetchImages(i);
    if (imageList.isEmpty) {
      FaceDetectorManager.instance.dispose();

      FaceRecognitionService().dispose();
      break;
    }
    List<Face> faces = [];
    File file;
    // List<double> embedding = [];
    List<List<double>> groupEmbedding = [];
    for (var image in imageList) {
      faces.clear();
      // embedding.clear();
      // groupEmbedding.clear();
      file = await image.file ?? File('');
      print("filepath: " + file.path);
      if (file.path.contains('.HEIC') ||
          file.path.contains('.heic') ||
          file.path.contains('.heif')) {
        String path = await ImageConverter.instance.convertHeicToJpg(file.path);
        file = File(path);
      }
      faces = await FaceDetectorManager.instance.detectFaces(file);
      if (faces.isNotEmpty && file.path.isNotEmpty) {
        for (var face in faces) {
          File croppedFile = await cropImage(file, face);
          groupEmbedding =
              await FaceRecognitionService().getFaceEmbeddings(croppedFile);
          var dbEmbeddingData = await dbHelper.getAllEmbeddings();

          for (var embedding in groupEmbedding) {
            if (dbEmbeddingData.isEmpty) {
              int id = await dbHelper.insertEmbedding(
                  basename(file.path), embedding);
              dbHelper.insertImagePath(id, file.path);
            } else {
              bool isInserted = false;
              for (var dbEmbedding in dbEmbeddingData) {
                bool similarity = FaceRecognitionService()
                    .cosineSimilarity(embedding, dbEmbedding.embedding);
                if (similarity) {
                  // found similarity
                  log('found similarity: ${dbEmbedding.id}');
                  dbHelper.insertImagePath(dbEmbedding.id, file.path);
                  isInserted = true;
                }
              }
              if (!isInserted) {
                dbHelper.insertEmbedding(basename(file.path), embedding);
              }
            }
          }
        }
      }
      await Future.delayed(Duration(seconds: 2));
    }
    await Future.delayed(Duration(seconds: 3));
  }
  return 'AI initialization finished';
}

// void startIsolate() async {
//   // Create a receive port to receive messages from the isolate
//   print('isolate started');
//   WidgetsFlutterBinding.ensureInitialized();

//   BackgroundIsolateBinaryMessenger.ensureInitialized(
//       RootIsolateToken.instance!);

//   ReceivePort mainReceivePort = ReceivePort();
//   Isolate isolate =
//       await Isolate.spawn(aiBackgroundTask, mainReceivePort.sendPort);

//   // Get the send port from the isolate
//   SendPort isolateSendPort = await mainReceivePort.first;

//   // Create another receive port to get the response from the isolate
//   ReceivePort responsePort = ReceivePort();
//   isolateSendPort.send(['initializeAI', responsePort.sendPort]);

//   // Get the response from the isolate
//   String result = await responsePort.first;
//   print('Isolate said: $result');

//   // Close the isolate once done
//   isolate.kill(priority: Isolate.immediate);
//   responsePort.close();
//   mainReceivePort.close();
//   print('isolate ended');
// }

// void main() {
//   runApp(MyApp());
//   startIsolate();
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: Text('Isolate Example with flutter_isolate')),
//         body: Center(
//           child: Text('Check the console for background isolate messages.'),
//         ),
//       ),
//     );
//   }
// }

Future<void> startIsolate() async {
  print('Isolate starting...');

  var isolate = await FlutterIsolate.spawn(aiBackgroundTask, 'main_send_port');

  // Listen for a message to indicate the task is completed
  ReceivePort receivePort = ReceivePort();
  receivePort.listen((data) {
    print('Received from isolate: $data');
    if (data == 'AI initialization finished') {
      receivePort.close();
      isolate.kill();
      print('Isolate finished and terminated.');
    }
  });

  // Send port to isolate for communication
  isolate.controlPort!.send(receivePort.sendPort);
}

void aiBackgroundTask(String message) async {
  print('Isolate running with message: $message');
  var result =
      await initializeAI(); // Assuming initializeAI() is an async function.
  SendPort? replyPort = IsolateNameServer.lookupPortByName('main_send_port');
  replyPort?.send(result);
}
