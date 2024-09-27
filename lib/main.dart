import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mediamanager/media.dart';
import 'package:mediamanager/mlkit.dart';
import 'package:mediamanager/tflite.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  List<AssetEntity> imageList = [];
  List<AssetEntity> personList = [];
  List<List<double>> faceEmbeddings = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                imageList = await fetchImages();
              },
              child: Text("Select images"),
            ),
            ElevatedButton(
              onPressed: () async {
                for (var element in imageList) {
                  fetchImageMetadata(element);
                }
              },
              child: Text("Fetch Location"),
            ),
            ElevatedButton(
              onPressed: () async {
                for (var element in imageList) {
                  int faces =
                      await detectFaces((await element.file) ?? File(''));
                  if (faces > 0) {
                    personList.add(element);
                  }
                }
              },
              child: Text("Detect Faces"),
            ),
            ElevatedButton(
              onPressed: () async {
                FaceRecognitionService().loadModel();
              },
              child: Text("load tflite model"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  for (var element in personList) {
                    faceEmbeddings.add(await FaceRecognitionService()
                            .getFaceEmbeddings(
                                (await element.file) ?? File('')) ??
                        []);
                  }
                  print(faceEmbeddings.length);
                } catch (e) {
                  print(e);
                }
              },
              child: Text("get face embeddings"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  for (int i = 0; i < faceEmbeddings.length; i++) {
                    for (int j = 0; j < faceEmbeddings.length; j++) {
                      bool isSame = await FaceRecognitionService()
                          .compareEmbeddings(
                              faceEmbeddings[i], faceEmbeddings[j]);
                      print(isSame);
                    }
                    print('\n');
                  }
                } catch (e) {
                  print(e);
                }
              },
              child: Text("compare faces"),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupedImagesView extends StatefulWidget {
  GroupedImagesView({super.key});

  @override
  State<GroupedImagesView> createState() => _GroupedImagesViewState();
}

class _GroupedImagesViewState extends State<GroupedImagesView> {
  Map<String, List<AssetEntity>> groupedImages = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: groupedImages.length,
        itemBuilder: (context, index) {
          String category = groupedImages.keys.elementAt(index);
          List<AssetEntity> images = groupedImages[category]!;

          return Column(
            children: [
              Text(category,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.file(
                    File(images[index].relativePath ?? ''),
                    fit: BoxFit.cover,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
