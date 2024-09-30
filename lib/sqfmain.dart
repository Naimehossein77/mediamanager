import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mediamanager/copImage.dart';
import 'package:mediamanager/image_converter_heic.dart';
import 'package:mediamanager/media.dart';
import 'package:mediamanager/mlkit.dart';
import 'package:mediamanager/sqflite.dart';
import 'package:mediamanager/tflite.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:path/path.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  List<File> personList = [];

  List<List<double>> faceEmbeddings = [];

  List<File> matchedImageList = [];
  List<int> label = [];
  List<ImageModel> imageModelList = [];
  DatabaseHelper dbHelper = DatabaseHelper();

  Future<List<AssetEntity>> selectImages(int page) async {
    return imageList = await fetchImages(page);
  }

  initializeAI() async {
    await FaceRecognitionService().loadModel();
    for (int i = 0; i < 10; i++) {
      this.imageList.clear();
      this.personList.clear();
      this.faceEmbeddings.clear();
      this.imageList = await selectImages(i);
      if (this.imageList.isEmpty) {
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
          String path =
              await ImageConverter.instance.convertHeicToJpg(file.path);
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
                for (var dbEmbedding in dbEmbeddingData) {
                  bool similarity = FaceRecognitionService()
                      .cosineSimilarity(embedding, dbEmbedding.embedding);
                  if (similarity) {
                    // found similarity
                    log('found similarity');
                    dbHelper.insertImagePath(dbEmbedding.id, file.path);
                  } else {
                    dbHelper.insertEmbedding(basename(file.path), embedding);
                  }
                }
              }
            }
          }
        }
       await Future.delayed(Duration(seconds: 2));
      }
      setState(() {});
      await Future.delayed(Duration(seconds: 3));
    }
  }

  getImageByUserId() async {
    this.imageModelList = await dbHelper.getImagesByUserId(3);
    print(this.imageModelList);
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeAI();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    DatabaseHelper().close();
    FaceDetectorManager.instance.dispose();
    FaceRecognitionService().dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    getImageByUserId();
                  },
                  child: Text("compare faces"),
                ),
                GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: imageModelList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, childAspectRatio: .7),
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          Image.file(File(imageModelList[index].imagePath)),
                          Text('${imageModelList[index].userId}')
                        ],
                      );
                    }),
                //   AssetEntityImage(
                //     matchedImageList[index],
                //     isOriginal: false, // Defaults to `true`.
                //     thumbnailSize:
                //         const ThumbnailSize.square(200), // Preferred value.
                //     thumbnailFormat:
                //         ThumbnailFormat.jpeg, // Defaults to `jpeg`.
                //   );
                // })
              ],
            ),
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
