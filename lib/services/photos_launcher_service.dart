import 'dart:io';

import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the system Photos app as a fallback (cannot deep-link to a single asset on iOS).
class PhotosLauncherService {
  static const MethodChannel _channel = MethodChannel('xrecorder/photos');

  Future<bool> openInPhotos(AssetEntity video) async {
    if (Platform.isIOS) {
      try {
        final opened = await _channel.invokeMethod<bool>(
          'openPhotosApp',
          {'localIdentifier': video.id},
        );
        if (opened == true) return true;
      } on MissingPluginException {
        // Fall through to URL scheme.
      } on PlatformException {
        // Fall through.
      }

      final uri = Uri.parse('photos-redirect://');
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    }

    if (Platform.isAndroid) {
      try {
        final opened = await _channel.invokeMethod<bool>(
          'openAssetInGallery',
          {'assetId': video.id},
        );
        return opened ?? false;
      } on MissingPluginException {
        await PhotoManager.openSetting();
        return true;
      }
    }

    await PhotoManager.openSetting();
    return true;
  }
}
