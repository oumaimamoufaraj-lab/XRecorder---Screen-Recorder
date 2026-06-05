import 'package:photo_manager/photo_manager.dart';

enum VideoSortMode { newest, oldest, longest }

class VideoLibraryService {
  Future<bool> hasPermission() async {
    final permission = await PhotoManager.requestPermissionExtend();
    return permission.isAuth || permission.hasAccess;
  }

  Future<List<AssetEntity>> loadVideos({
    int page = 0,
    int size = 100,
  }) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );
    if (albums.isEmpty) return const [];
    return albums.first.getAssetListPaged(page: page, size: size);
  }

  List<AssetEntity> filterByQuery(List<AssetEntity> videos, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return videos;
    return videos.where((v) {
      final title = (v.title ?? 'screen recording').toLowerCase();
      return title.contains(q);
    }).toList();
  }

  List<AssetEntity> sortVideos(List<AssetEntity> videos, VideoSortMode mode) {
    final sorted = List<AssetEntity>.from(videos);
    switch (mode) {
      case VideoSortMode.newest:
        sorted.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
      case VideoSortMode.oldest:
        sorted.sort((a, b) => a.createDateTime.compareTo(b.createDateTime));
      case VideoSortMode.longest:
        sorted.sort((a, b) => b.duration.compareTo(a.duration));
    }
    return sorted;
  }

  Future<bool> deleteVideo(AssetEntity video) async {
    final result = await PhotoManager.editor.deleteWithIds([video.id]);
    return result.isNotEmpty;
  }
}
