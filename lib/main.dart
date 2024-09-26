import 'dart:io';

import 'package:flutter/material.dart';
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
      home: GroupedImagesView(),
    );
  }
}

class GroupedImagesView extends StatelessWidget {
  GroupedImagesView({super.key});

  Map<String, List<AssetEntity>> groupedImages = {};
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
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
    );
  }
}
