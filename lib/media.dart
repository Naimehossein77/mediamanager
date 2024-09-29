import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestGalleryPermissions() async {
  var status = await Permission.photos.request();
  if (status.isGranted) {
    // If permission is granted, fetch the images
    await fetchImages();
  } else {
    print("Permission denied");
  }
}

Future<List<AssetEntity>> fetchImages() async {
  List<AssetEntity> images = [];

  // Request permission first
  await PhotoManager.requestPermissionExtend(
      requestOption: PermissionRequestOption(
          androidPermission:
              AndroidPermission(type: RequestType.image, mediaLocation: true)));
  PermissionStatus permission = await Permission.photos.request();
  print(permission);
  if (permission.isGranted) {
    // Fetch all images from the gallery

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      onlyAll: false,
      hasAll: true,
      type: RequestType.image,
    );
    print(albums);
    List<AssetEntity> assets = [];

    for (var path in albums) {
    assets = await path.getAssetListPaged(page: 0, size: 10);
      images.addAll(assets);
    }

    for (var asset in images) {
      print("Image: ${asset.title}");
    }
    return assets;
  } else {
    print("Permission not granted");
    return [];
  }
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
