import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

Future<PermissionStatus> requestStoragePhotosPermission() async {
  await PhotoManager.requestPermissionExtend(
      requestOption: PermissionRequestOption(
          androidPermission:
              AndroidPermission(type: RequestType.image, mediaLocation: true)));
  PermissionStatus permission;
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt <= 32) {
      /// use [Permissions.storage.status]
      permission = await Permission.storage.request();
    } else {
      /// use [Permissions.photos.status]
      permission = await Permission.photos.request();
    }
  } else {
    permission = await Permission.photos.request();
  }
  return permission;
}

Future<List<AssetEntity>> fetchImages(int page) async {
  List<AssetEntity> images = [];

  // Request permission first

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      hasAll: false,
      type: RequestType.image,
    );
    print(albums);
    List<AssetEntity> assets = [];

    for (var path in albums) {
      assets = await path.getAssetListPaged(page: page, size: 10);
      images.addAll(assets);
    }

    for (var asset in images) {
      print("Image: ${asset.relativePath}");
    }
    return assets;
  }

Future<void> fetchImageMetadata(AssetEntity asset) async {
  var location = asset.latitude; // Get latitude
  var longitude = asset.longitude; // Get longitude

  if (location != null && longitude != null) {
    print("Image location: Lat $location, Lon $longitude");
  } else {
    print("No location data available for this image.");
  }
}
