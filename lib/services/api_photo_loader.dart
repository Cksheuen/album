import '../models/photo_model.dart';
import '../services/image_api_service.dart';

/// API 图片加载器
/// 封装从 API 加载图片的所有逻辑
class ApiPhotoLoader {
  // 已加载的图片URL集合，用于去重
  final Set<String> _loadedImageUrls = {};

  // 当前加载页数
  int _currentPage = 0;

  // 每页加载数量
  final int pageSize;

  // 自动加载间隔（秒）
  final int autoLoadIntervalSeconds;

  // 是否正在自动加载
  bool _isAutoLoading = false;

  // 是否还有更多图片
  bool hasMore = true;

  ApiPhotoLoader({this.pageSize = 10, this.autoLoadIntervalSeconds = 10});

  /// 加载指定数量的图片
  ///
  /// [count] 要加载的图片数量
  /// 返回 PhotoModel 列表
  Future<List<PhotoModel>> loadPhotos(int count) async {
    final List<PhotoModel> photos = [];

    if (count == 1) {
      print('📡 [API] 请求1张图片...');
    } else {
      print('📡 [API] 请求 $count 张图片（间隔${autoLoadIntervalSeconds}秒/张）...');
    }

    final startTime = DateTime.now();

    // 使用快速模式（TXT格式）批量获取图片
    final imageUrls = await ImageApiService.getBatchImagesFast(
      count: count,
      imageType: ImageApiService.IMAGE_TYPE_GENERAL,
      delayMs: count > 1 ? autoLoadIntervalSeconds * 1000 : 0, // 单张图片不需要延迟
    );

    final duration = DateTime.now().difference(startTime);
    print(
      '📥 [API] 成功获取 ${imageUrls.length}/$count 个图片URL（耗时: ${duration.inSeconds}秒）',
    );

    // 生成PhotoModel，每张图片分配随机日期
    final now = DateTime.now();
    int successCount = 0;
    int skipCount = 0;

    for (int i = 0; i < imageUrls.length; i++) {
      final url = imageUrls[i];

      // 验证URL格式
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        print('⚠️ [API] 无效的URL格式: $url');
        skipCount++;
        continue;
      }

      // 跳过已加载的URL，去重
      if (_loadedImageUrls.contains(url)) {
        print('⚠️ [API] 跳过重复URL: ${url.substring(0, 50)}...');
        skipCount++;
        continue;
      }

      // 生成随机日期（最近3个月内）
      final daysAgo = (i * 2.5).toInt();
      final photoDate = now.subtract(Duration(days: daysAgo));

      photos.add(
        PhotoModel(
          path: url,
          date: photoDate,
          title: 'API图片${_loadedImageUrls.length + successCount + 1}',
          tags: _generateRandomTags(i),
          isNetworkImage: true,
        ),
      );

      _loadedImageUrls.add(url);
      successCount++;
    }

    if (skipCount > 0) {
      print('⚠️ [API] 跳过了 $skipCount 个无效/重复的URL');
    }

    // 按日期降序排列
    photos.sort((a, b) => b.date.compareTo(a.date));

    print('✅ [API] 成功处理 $successCount 张图片');
    return photos;
  }

  /// 开始自动加载图片
  ///
  /// [targetCount] 目标总数
  /// [onPhotoLoaded] 每加载一张图片的回调
  /// [onComplete] 加载完成的回调
  Future<void> startAutoLoading({
    required int targetCount,
    required int currentCount,
    required Function(List<PhotoModel>) onPhotoLoaded,
    Function()? onComplete,
  }) async {
    if (_isAutoLoading) {
      print('⚠️ [API] 自动加载已在进行中');
      return;
    }

    _isAutoLoading = true;
    print('🔄 [API] 开始自动加载，目标 $targetCount 张图片...');

    int loadedCount = currentCount;

    while (loadedCount < targetCount && hasMore) {
      await Future.delayed(Duration(seconds: autoLoadIntervalSeconds));

      // 每次加载1张
      final newPhotos = await loadPhotos(1);

      if (newPhotos.isEmpty) {
        print('⚠️ [API] 没有更多图片了');
        hasMore = false;
        break;
      }

      loadedCount++;
      onPhotoLoaded(newPhotos);

      print('➕ [API] 新增1张图片，当前共 $loadedCount 张');
    }

    _isAutoLoading = false;
    print('✅ [API] 自动加载完成，总共 $loadedCount 张图片');

    if (onComplete != null) {
      onComplete();
    }
  }

  /// 停止自动加载
  void stopAutoLoading() {
    if (_isAutoLoading) {
      _isAutoLoading = false;
      print('🛑 [API] 停止自动加载');
    }
  }

  /// 重置加载器
  void reset() {
    stopAutoLoading();
    _loadedImageUrls.clear();
    _currentPage = 0;
    hasMore = true;
    print('🔄 [API] 加载器已重置');
  }

  /// 加载更多图片（分页）
  Future<List<PhotoModel>> loadMore() async {
    if (!hasMore) {
      print('⚠️ [API] 没有更多图片了');
      return [];
    }

    _currentPage++;
    print('📄 [API] 加载第 $_currentPage 页...');

    final newPhotos = await loadPhotos(pageSize);

    if (newPhotos.isEmpty) {
      hasMore = false;
    }

    return newPhotos;
  }

  /// 生成随机标签
  List<String> _generateRandomTags(int index) {
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

  /// 获取统计信息
  Map<String, dynamic> getStats() {
    return {
      'totalLoaded': _loadedImageUrls.length,
      'currentPage': _currentPage,
      'hasMore': hasMore,
      'isAutoLoading': _isAutoLoading,
    };
  }
}
