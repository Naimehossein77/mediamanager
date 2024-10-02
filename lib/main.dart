import 'dart:async';
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
import 'package:mediamanager/view/grouped_image_view.dart';
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
  List<EmbeddingData> embeddingDataList = [];
  DatabaseHelper dbHelper = new DatabaseHelper();
  late Timer timer;

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

  getAllEmbeddings() async {
    await dbHelper.initDatabase();
    this.embeddingDataList = await DatabaseHelper().getAllEmbeddings();
    setState(() {});
  }

  requestPermissionAndCallAI() async {
    PermissionStatus status = await requestStoragePhotosPermission();
    if (status.isGranted) {
      print('permission granted');
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'embeddings.db');
      deleteDatabase(path);
      await startIsolate();
      timer = Timer.periodic(Duration(seconds: 5), (timer) {
        getAllEmbeddings();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel;
    DatabaseHelper().close();
    FaceDetectorManager.instance.dispose();
    FaceRecognitionService().dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('StoryBox\'s')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(193, 171, 135, 177),
                  ),
                  onPressed: () async {
                    // print(await getAllEmbeddings());
                    var len = (await fetchImages(0)).length;
                    // print(len);
                  },
                  child: Text("Refresh"),
                ),
                SizedBox(height: 20),
                GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: embeddingDataList.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8),
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () async {
                          await getImageByUserId(
                              this.embeddingDataList[index].id);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => GroupedImageView(
                                      imageModelList: imageModelList)));
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(193, 171, 135, 177),
                          ),
                          // child: Text(
                          //   '${embeddingDataList[index].label}',
                          //   textAlign: TextAlign.center,
                          // ),
                          child: Image.file(
                            File(
                              embeddingDataList[index].label,
                            ),
                            fit: BoxFit.cover,
                            height: double.infinity,
                            width: double.infinity,
                          ),
                        ),
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
