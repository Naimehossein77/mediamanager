import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mediamanager/media.dart';
import 'package:mediamanager/mlkit.dart';
import 'package:mediamanager/tflite.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

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

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<AssetEntity> imageList = [];

  List<AssetEntity> personList = [];

  List<List<double>> faceEmbeddings = [];

  List<AssetEntity> matchedImageList = [];

  Future<List<AssetEntity>> selectImages() async {
    return imageList = await fetchImages();
  }

  void fetchAllImageMetadata(List<AssetEntity> imageList) async {
    for (var element in imageList) {
      fetchImageMetadata(element);
    }
  }

  Future<List<AssetEntity>> getDetectedFaces(
      List<AssetEntity> imageList) async {
    List<AssetEntity> personList = [];
    for (var element in imageList) {
      int faces = await detectFaces((await element.file) ?? File(''));
      if (faces > 0) {
        personList.add(element);
      }
    }
    return personList;
  }

  Future<List<List<double>>> getAllPersonFaceEmbedding(
      List<AssetEntity> personList) async {
    try {
      for (var element in personList) {
        faceEmbeddings.addAll(await FaceRecognitionService()
            .getFaceEmbeddings((await element.file) ?? File('')));
      }
      print(faceEmbeddings.length);
      return faceEmbeddings;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<AssetEntity>> compareFaces(List<AssetEntity> personList) async {
    try {
      List<AssetEntity> matchedList = [];
      for (int i = 0; i < faceEmbeddings.length; i++) {
        for (int j = i + 1; j < faceEmbeddings.length; j++) {
          bool isSame = await FaceRecognitionService()
              .cosineSimilarity(faceEmbeddings[i], faceEmbeddings[j]);
          if (isSame) {
            matchedList.add(personList[i]);
            matchedList.add(personList[j]);
          }
        }
      }
      return matchedList;
    } catch (e) {
      print(e);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Align(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  this.imageList = await selectImages();
                },
                child: Text("Select images"),
              ),
              ElevatedButton(
                onPressed: () async {
                  fetchAllImageMetadata(this.imageList);
                },
                child: Text("Fetch Location"),
              ),
              ElevatedButton(
                onPressed: () async {
                  this.personList = await getDetectedFaces(this.imageList);
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
                  getAllPersonFaceEmbedding(this.imageList);
                },
                child: Text("get face embeddings"),
              ),
              ElevatedButton(
                onPressed: () async {
                  this.matchedImageList = await compareFaces(this.imageList);
                  setState(() {});
                },
                child: Text("compare faces"),
              ),
              GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: matchedImageList.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2),
                  itemBuilder: (context, index) {
                    return AssetEntityImage(
                      matchedImageList[index],
                      isOriginal: false, // Defaults to `true`.
                      thumbnailSize:
                          const ThumbnailSize.square(200), // Preferred value.
                      thumbnailFormat:
                          ThumbnailFormat.jpeg, // Defaults to `jpeg`.
                    );
                  })
            ],
          ),
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
