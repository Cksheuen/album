import 'package:get/get.dart';
import '../../models/photo_model.dart';
import '../../mock/photo_mock_data.dart';
import '../../services/api_photo_loader.dart';

enum GroupType { year, month, day }

enum SortType { dateAsc, dateDesc }

class SplashController extends GetxController {
  // 响应式变量
  final RxList<PhotoModel> _allPhotos = <PhotoModel>[].obs;
  final RxMap<String, List<PhotoModel>> _groupedPhotos =
      <String, List<PhotoModel>>{}.obs;
  final Rx<GroupType> _currentGroupType = GroupType.month.obs;
  final Rx<SortType> _currentSortType = SortType.dateDesc.obs;
  final RxBool _isLoading = true.obs;
  final RxBool _isLoadingMore = false.obs;
  final RxString _selectedTag = ''.obs;

  // 懒加载相关
  int _currentPage = 0;
  bool _hasMore = true;

  // API加载器（供以后使用）
  final ApiPhotoLoader apiLoader = ApiPhotoLoader(
    pageSize: 10,
    autoLoadIntervalSeconds: 10,
  );

  // Getters
  List<PhotoModel> get allPhotos => _allPhotos;
  Map<String, List<PhotoModel>> get groupedPhotos => Map.from(_groupedPhotos);
  GroupType get currentGroupType => _currentGroupType.value;
  SortType get currentSortType => _currentSortType.value;
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get hasMore => _hasMore;
  String get selectedTag => _selectedTag.value;

  // 获取封面图片
  PhotoModel? get coverPhoto => _allPhotos.isNotEmpty ? _allPhotos.first : null;

  @override
  void onInit() {
    super.onInit();
    _initializePhotos();
  }

  // 初始化照片数据
  Future<void> _initializePhotos() async {
    try {
      _isLoading.value = true;

      // 方式1: 从本地Assets加载（默认，推荐：快速加载）
      print('📸 从本地Assets加载图片...');
      final photos = PhotoMockData.generateMockPhotos();

      // 方式2: 从API加载（可选：动态内容，自动加载）
      // 如需使用API模式，请调用 switchToApiMode() 方法
      // print('🌐 从API加载图片...');
      // final photos = await apiLoader.loadPhotos(1);
      // apiLoader.startAutoLoading(
      //   targetCount: _pageSize,
      //   currentCount: photos.length,
      //   onPhotoLoaded: (newPhotos) {
      //     _allPhotos.addAll(newPhotos);
      //     _updateGroupedPhotos();
      //   },
      // );

      _allPhotos.value = photos;
      _updateGroupedPhotos();

      // 本地Assets模式：所有图片一次性加载完成，不需要"加载更多"
      _hasMore = false;

      print('✅ 初始化完成，加载了 ${photos.length} 张照片');
      _isLoading.value = false;
    } catch (e) {
      print('❌ 初始化照片失败: $e');
      _isLoading.value = false;
      // 失败时使用本地mock数据作为后备
      final photos = PhotoMockData.generateMockPhotos();
      _allPhotos.value = photos;
      _updateGroupedPhotos();
      _hasMore = false; // 本地模式无需加载更多
    }
  }

  // 更新分组后的照片数据
  void _updateGroupedPhotos() {
    List<PhotoModel> filteredPhotos = _allPhotos;

    if (_selectedTag.value.isNotEmpty) {
      filteredPhotos = _allPhotos.where((photo) {
        return photo.tags?.contains(_selectedTag.value) == true;
      }).toList();
    }

    filteredPhotos.sort((a, b) {
      return _currentSortType.value == SortType.dateAsc
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date);
    });

    Map<String, List<PhotoModel>> grouped;
    switch (_currentGroupType.value) {
      case GroupType.year:
        grouped = PhotoMockData.groupPhotosByYear(filteredPhotos);
      case GroupType.day:
        grouped = PhotoMockData.groupPhotosByDay(filteredPhotos);
      case GroupType.month:
        grouped = PhotoMockData.groupPhotosByMonth(filteredPhotos);
    }

    _groupedPhotos.clear();
    _groupedPhotos.addAll(grouped);
  }

  List<String> get groupTitles => _groupedPhotos.keys.toList();

  Future<void> loadMorePhotos() async {
    if (_isLoadingMore.value || !_hasMore) {
      return;
    }

    try {
      _isLoadingMore.value = true;

      _currentPage++;
      print('📄 加载第 $_currentPage 页（使用API）...');

      final newPhotos = await apiLoader.loadMore();

      if (newPhotos.isEmpty) {
        _hasMore = false;
        print('⚠️ 没有更多图片了');
      } else {
        _allPhotos.addAll(newPhotos);
        _updateGroupedPhotos();
        print('✅ 加载更多: 第${_currentPage}页, 新增${newPhotos.length}张');
      }
    } catch (e) {
      print('❌ 加载更多失败: $e');
    } finally {
      _isLoadingMore.value = false;
    }
  }

  void changeGroupType(GroupType newType) {
    if (_currentGroupType.value != newType) {
      _currentGroupType.value = newType;
      _updateGroupedPhotos();
    }
  }

  void changeSortType(SortType newType) {
    if (_currentSortType.value != newType) {
      _currentSortType.value = newType;
      _updateGroupedPhotos();
    }
  }

  void filterByTag(String tag) {
    if (_selectedTag.value != tag) {
      _selectedTag.value = tag;
      _updateGroupedPhotos();
    }
  }

  void clearFilter() {
    if (_selectedTag.value.isNotEmpty) {
      _selectedTag.value = '';
      _updateGroupedPhotos();
    }
  }

  Set<String> get allTags {
    Set<String> allTags = {};
    for (var photo in _allPhotos) {
      if (photo.tags != null) {
        allTags.addAll(photo.tags!);
      }
    }
    return allTags;
  }

  Future<void> refresh() async {
    print('🔄 刷新数据...');

    // 停止API自动加载
    apiLoader.stopAutoLoading();

    _currentPage = 0;
    _hasMore = true;
    _allPhotos.clear();
    _groupedPhotos.clear();

    await _initializePhotos();
  }

  /// 切换到API模式（供以后调用）
  Future<void> switchToApiMode() async {
    print('🔄 切换到API模式...');
    _isLoading.value = true;
    _allPhotos.clear();
    _groupedPhotos.clear();
    apiLoader.reset();

    final photos = await apiLoader.loadPhotos(1);
    _allPhotos.value = photos;
    _updateGroupedPhotos();

    // API模式：支持加载更多
    _hasMore = true;
    _currentPage = 1;

    _isLoading.value = false;

    // 启动自动加载
    apiLoader.startAutoLoading(
      targetCount: 10,
      currentCount: photos.length,
      onPhotoLoaded: (newPhotos) {
        _allPhotos.addAll(newPhotos);
        _updateGroupedPhotos();
      },
    );
  }

  /// 切换到本地Assets模式（供以后调用）
  void switchToLocalMode() {
    print('🔄 切换到本地模式...');
    apiLoader.stopAutoLoading();
    _allPhotos.value = PhotoMockData.generateMockPhotos();
    _updateGroupedPhotos();

    // 本地模式：所有图片已加载，无需加载更多
    _hasMore = false;
    _currentPage = 0;

    print('✅ 已切换到本地模式');
  }

  @override
  void onClose() {
    // 停止API自动加载
    apiLoader.stopAutoLoading();
    super.onClose();
  }
}
