import 'package:photo_manager/photo_manager.dart';

/// Photos library access without prompting until explicitly requested.
abstract final class PhotosPermissionService {
  static const _requestOption = PermissionRequestOption();

  /// Set after the user opens Clips or starts a recording — gates Home/Shield
  /// from touching the photo library on launch (even if OS permission exists).
  static bool libraryBrowseUnlocked = false;

  static bool get canBrowseLibrary => libraryBrowseUnlocked;

  /// Call when the user explicitly opens Clips or begins recording.
  static void unlockLibraryBrowse() {
    libraryBrowseUnlocked = true;
  }

  /// Returns whether Photos access is already granted (no system prompt).
  static Future<bool> isAccessGranted() async {
    final state = await PhotoManager.getPermissionState(
      requestOption: _requestOption,
    );
    return state.hasAccess;
  }

  /// Shows the system Photos permission prompt when needed.
  static Future<bool> requestAccess() async {
    unlockLibraryBrowse();
    final state = await PhotoManager.requestPermissionExtend(
      requestOption: _requestOption,
    );
    return state.hasAccess;
  }
}
