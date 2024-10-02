import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mediamanager/sqflite.dart';

class GroupedImageView extends StatelessWidget {
  const GroupedImageView({super.key, required this.imageModelList});
  final List<ImageModel> imageModelList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inside Box'),
      ),
      body: SafeArea(
        child: GridView.builder(
            shrinkWrap: true,
            // physics: NeverScrollableScrollPhysics(),
            itemCount: imageModelList.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 1),
            itemBuilder: (context, index) {
              return Image.file(File(imageModelList[index].imagePath));
            }),
      ),
    );
  }
}
