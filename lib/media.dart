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

Future<void> fetchImages() async {
  List<AssetEntity> images = [];

  // Request permission first
  final permission = await PhotoManager.requestPermissionExtend();
  if (permission.isAuth) {
    // Fetch all images from the gallery
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );
    final List<AssetEntity> assets = await albums.first.getAssetListPaged(page: 0,size: 100);
    images.addAll(assets);
    
    for (var asset in images) {
      print("Image: ${asset.title}");
    }
  } else {
    print("Permission not granted");
  }
}

Future<void> fetchImageMetadata(AssetEntity asset) async {
  var location =  asset.latitude;  // Get latitude
  var longitude = asset.longitude; // Get longitude

  if (location != null && longitude != null) {
    print("Image location: Lat $location, Lon $longitude");
  } else {
    print("No location data available for this image.");
  }
}
