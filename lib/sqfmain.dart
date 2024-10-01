import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mediamanager/copImage.dart';
import 'package:mediamanager/image_converter_heic.dart';
import 'package:mediamanager/isolate_thread.dart';
import 'package:mediamanager/media.dart';
import 'package:mediamanager/mlkit.dart';
import 'package:mediamanager/sqflite.dart';
import 'package:mediamanager/tflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  BackgroundIsolateBinaryMessenger.ensureInitialized(
      RootIsolateToken.instance!);
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
  List<ImageModel> imageModelList = [];
  DatabaseHelper dbHelper = new DatabaseHelper();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    requestPermissionAndCallAI();
  }

  getImageByUserId(int id) async {
    this.imageModelList = await dbHelper.getImagesByUserId(id);
    print(this.imageModelList);
    setState(() {});
  }

  requestPermissionAndCallAI() async {
    PermissionStatus status = await requestStoragePhotosPermission();
    if (status.isGranted) {
      print('permission granted');
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'embeddings.db');
      deleteDatabase(path);
      startIsolate();
    }
  }
  @override
  void dispose() {
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
                    await dbHelper.initDatabase();
                    for (int i = 0; i < 10; i++) await getImageByUserId(i);
                    // print(await dbHelper.getAllEmbeddings());
                    dbHelper.close();
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
