import '../models/photo_model.dart';
import '../common/utils/assets_image_manager.dart';

class PhotoMockData {
  static List<PhotoModel> generateMockPhotos() {
    // 自动从 AssetsImageManager 获取所有图片路径
    final List<String> imagePaths = AssetsImageManager.getAllImagePaths();

    final List<PhotoModel> photos = [];

    // 生成不同时间的照片数据
    for (int i = 0; i < imagePaths.length; i++) {
      DateTime photoDate;

      if (i < 6) {
        // 2024年10月的照片
        photoDate = DateTime(2024, 10, 15 - i, 14, 30 + i * 10);
      } else if (i < 12) {
        // 2024年9月的照片
        photoDate = DateTime(2024, 9, 28 - (i - 6), 16, 20 + i * 5);
      } else {
        // 2024年8月的照片
        photoDate = DateTime(2024, 8, 25 - (i - 12), 18, 10 + i * 8);
      }

      photos.add(
        PhotoModel(
          path: imagePaths[i],
          date: photoDate,
          title: '照片${i + 1}',
          tags: _generateRandomTags(i),
        ),
      );
    }

    // 按日期降序排列（最新的在前面）
    photos.sort((a, b) => b.date.compareTo(a.date));

    return photos;
  }

  static List<String> _generateRandomTags(int index) {
    final List<List<String>> tagOptions = [
      ['风景', '自然'],
      ['人物', '肖像'],
      ['动物', '可爱'],
      ['建筑', '城市'],
      ['美食', '生活'],
      ['旅行', '记录'],
      ['艺术', '创意'],
      ['运动', '活力'],
    ];

    return tagOptions[index % tagOptions.length];
  }

  // 按时间分组的方法
  static Map<String, List<PhotoModel>> groupPhotosByMonth(
    List<PhotoModel> photos,
  ) {
    final Map<String, List<PhotoModel>> groupedPhotos = {};

    for (final photo in photos) {
      final key = photo.yearMonth;
      if (!groupedPhotos.containsKey(key)) {
        groupedPhotos[key] = [];
      }
      groupedPhotos[key]!.add(photo);
    }

    return groupedPhotos;
  }

  static Map<String, List<PhotoModel>> groupPhotosByYear(
    List<PhotoModel> photos,
  ) {
    final Map<String, List<PhotoModel>> groupedPhotos = {};

    for (final photo in photos) {
      final key = photo.year;
      if (!groupedPhotos.containsKey(key)) {
        groupedPhotos[key] = [];
      }
      groupedPhotos[key]!.add(photo);
    }

    return groupedPhotos;
  }

  static Map<String, List<PhotoModel>> groupPhotosByDay(
    List<PhotoModel> photos,
  ) {
    final Map<String, List<PhotoModel>> groupedPhotos = {};

    for (final photo in photos) {
      final key = photo.yearMonthDay;
      if (!groupedPhotos.containsKey(key)) {
        groupedPhotos[key] = [];
      }
      groupedPhotos[key]!.add(photo);
    }

    return groupedPhotos;
  }
}
