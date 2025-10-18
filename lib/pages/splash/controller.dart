import 'dart:async';
import 'package:flutter/widgets.dart';
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
  
  // 加载占位符标记
  final RxBool _hasLoadingPlaceholder = false.obs;
  
  // 自动滚动到新内容的控制
  final RxBool _autoScrollToNew = true.obs;
  
  // 插入占位符的位置信息
  final RxString _insertPlaceholderGroup = ''.obs;
  final RxInt _insertPlaceholderPosition = (-1).obs;
  
  // 插入占位符显示的选中图片信息
  final RxString _selectedImagePath = ''.obs;
  final RxBool _isSelectedImageFromAssets = true.obs;
  
  // 防抖计时器，避免频繁更新
  Timer? _placeholderUpdateTimer;
  
  // 滚动控制器（由 View 层设置）
  ScrollController? scrollController;
  
  // 插入面板是否显示
  final RxBool _isInsertPanelVisible = false.obs;
  
  // 新图片加载回调（通知 UI 滚动到底部）
  Function()? onNewPhotoLoaded;
  
  // 加载模式标志：true=API模式，false=本地Assets模式
  bool _isApiMode = false;

  // 懒加载相关
  int _currentPage = 0;
  bool _hasMore = true;
  
  // 加载占位符照片（特殊标记，用于显示加载动画）
  static final PhotoModel _loadingPlaceholder = PhotoModel(
    path: '__loading_placeholder__',  // 特殊路径标记
    date: DateTime.now(),
    title: '加载中...',
    tags: ['loading'],
  );

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
  bool get isInsertPanelVisible => _isInsertPanelVisible.value;
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  bool get hasMore => _hasMore;
  String get selectedTag => _selectedTag.value;
  
  // 是否显示加载占位符
  bool get hasLoadingPlaceholder => _hasLoadingPlaceholder.value;
  
  // 是否自动滚动到新内容
  bool get autoScrollToNew => _autoScrollToNew.value;
  
  // 获取插入占位符的位置信息
  String get insertPlaceholderGroup => _insertPlaceholderGroup.value;
  int get insertPlaceholderPosition => _insertPlaceholderPosition.value;
  bool get hasInsertPlaceholder => _insertPlaceholderGroup.value.isNotEmpty;
  
  // 获取选中的图片信息
  String get selectedImagePath => _selectedImagePath.value;
  bool get isSelectedImageFromAssets => _isSelectedImageFromAssets.value;
  bool get hasSelectedImage => _selectedImagePath.value.isNotEmpty;

  // 获取封面图片（过滤掉加载占位符）
  PhotoModel? get coverPhoto {
    if (_allPhotos.isEmpty) return null;
    
    // 查找第一个非占位符的照片
    final realPhoto = _allPhotos.firstWhere(
      (photo) => photo.path != '__loading_placeholder__',
      orElse: () => _allPhotos.first, // 如果全是占位符，返回第一个
    );
    
    // 如果找到的还是占位符，返回 null
    return realPhoto.path == '__loading_placeholder__' ? null : realPhoto;
  }

  @override
  void onInit() {
    super.onInit();
    _initializePhotos();
  }

  // 初始化照片数据
  Future<void> _initializePhotos() async {
    try {
      _isLoading.value = true;

      // 方式1: 从本地Assets流式懒加载（默认，推荐：实时更新UI，模拟真实加载体验）
      print('📸 从本地Assets流式懒加载图片...');
      
      await PhotoMockData.generateMockPhotosLazyStream(
        onPhotoLoaded: (photo, index, total) {
          // 第一张图片加载后，添加占位符（确保封面不是占位符）
          if (index == 0) {
            _allPhotos.add(photo);
            _updateGroupedPhotos();
            print('🔄 UI已更新: ${index + 1}/$total 张图片');
            // 第一张图片加载完成后，添加占位符
            _addLoadingPlaceholder();
          } else {
            // 后续图片：移除旧占位符（不更新UI） -> 添加新照片 -> 添加新占位符（一次性更新UI）
            _removeLoadingPlaceholder(updateUI: false);
            _allPhotos.add(photo);
            
            // 如果还有更多图片要加载，添加占位符；否则只更新UI
            if (index < total - 1) {
              _addLoadingPlaceholder(updateUI: true); // 添加占位符并更新UI
            } else {
              _updateGroupedPhotos(); // 最后一张图片，只更新UI不添加占位符
            }
            
            print('🔄 UI已更新: ${index + 1}/$total 张图片');
            
            // 触发自动滚动（如果开启）
            if (_autoScrollToNew.value && onNewPhotoLoaded != null) {
              onNewPhotoLoaded!();
            }
          }
        },
      );

      // 方式1B: 从本地Assets懒加载（可选：一次性返回所有）
      // print('📸 从本地Assets懒加载图片...');
      // final photos = await PhotoMockData.generateMockPhotosLazy();
      // _allPhotos.value = photos;
      // _updateGroupedPhotos();

      // 方式1C: 从本地Assets快速加载（可选：无延迟）
      // print('📸 从本地Assets加载图片...');
      // final photos = PhotoMockData.generateMockPhotos();
      // _allPhotos.value = photos;
      // _updateGroupedPhotos();

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

      // 本地Assets模式：所有图片一次性加载完成，不需要"加载更多"
      _isApiMode = false;
      _hasMore = false;

      print('✅ 初始化完成，加载了 ${_allPhotos.length} 张照片（本地Assets模式）');
      _isLoading.value = false;
    } catch (e) {
      print('❌ 初始化照片失败: $e');
      _isLoading.value = false;
      // 失败时使用本地mock数据作为后备（同步模式）
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

    // 分离占位符和真实照片 - 占位符不参与分组
    final realPhotos = filteredPhotos.where((p) => p.path != '__loading_placeholder__').toList();

    // 只对真实照片排序
    realPhotos.sort((a, b) {
      return _currentSortType.value == SortType.dateAsc
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date);
    });

    // 只对真实照片进行分组（占位符将在 view 层通过绝对定位渲染）
    Map<String, List<PhotoModel>> grouped;
    switch (_currentGroupType.value) {
      case GroupType.year:
        grouped = PhotoMockData.groupPhotosByYear(realPhotos);
      case GroupType.day:
        grouped = PhotoMockData.groupPhotosByDay(realPhotos);
      case GroupType.month:
        grouped = PhotoMockData.groupPhotosByMonth(realPhotos);
    }

    _groupedPhotos.clear();
    _groupedPhotos.addAll(grouped);
  }

  List<String> get groupTitles => _groupedPhotos.keys.toList();

  /// 加载更多照片（仅在API模式下使用）
  /// 本地Assets模式下，所有图片已一次性加载完成，不需要此方法
  Future<void> loadMorePhotos() async {
    if (_isLoadingMore.value || !_hasMore) {
      return;
    }

    // 检查是否在 API 模式下
    if (!_isApiMode) {
      print('⚠️ 当前在本地Assets模式，不支持加载更多');
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

  /// 添加加载占位符到最后一组的最后一位
  /// [updateUI] 是否立即更新UI，默认为true
  void _addLoadingPlaceholder({bool updateUI = true}) {
    if (_hasLoadingPlaceholder.value) return; // 防止重复添加
    
    print('➕ 添加加载占位符');
    _allPhotos.add(_loadingPlaceholder);
    _hasLoadingPlaceholder.value = true;
    if (updateUI) {
      _updateGroupedPhotos();
    }
  }

  /// 移除加载占位符
  /// [updateUI] 是否立即更新UI，默认为true
  void _removeLoadingPlaceholder({bool updateUI = true}) {
    if (!_hasLoadingPlaceholder.value) return; // 没有占位符则不处理
    
    print('➖ 移除加载占位符');
    _allPhotos.removeWhere((photo) => photo.path == '__loading_placeholder__');
    _hasLoadingPlaceholder.value = false;
    if (updateUI) {
      _updateGroupedPhotos();
    }
  }

  @override
  Future<void> refresh() async {
    print('🔄 刷新数据...');

    // 停止API自动加载
    apiLoader.stopAutoLoading();

    _currentPage = 0;
    _hasMore = true;
    _allPhotos.clear();
    _groupedPhotos.clear();
    
    // 立即更新UI，显示空状态
    _updateGroupedPhotos();

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
    _isApiMode = true;
    _hasMore = true;
    _currentPage = 1;

    _isLoading.value = false;

    print('✅ 已切换到API模式');

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

  /// 切换到本地Assets流式懒加载模式（供以后调用）
  Future<void> switchToLocalMode() async {
    print('🔄 切换到本地流式懒加载模式...');
    apiLoader.stopAutoLoading();
    
    _isLoading.value = true;
    _allPhotos.clear();
    _groupedPhotos.clear();
    _updateGroupedPhotos(); // 立即显示空状态
    
    await PhotoMockData.generateMockPhotosLazyStream(
      onPhotoLoaded: (photo, index, total) {
        _allPhotos.add(photo);
        _updateGroupedPhotos();
        print('🔄 UI已更新: ${index + 1}/$total 张图片');
      },
    );

    // 本地模式：所有图片已加载，无需加载更多
    _isApiMode = false;
    _hasMore = false;
    _currentPage = 0;
    _isLoading.value = false;

    print('✅ 已切换到本地流式懒加载模式');
  }

  /// 切换到本地Assets懒加载模式（一次性返回，供以后调用）
  Future<void> switchToLocalModeLazy() async {
    print('🔄 切换到本地懒加载模式...');
    apiLoader.stopAutoLoading();
    
    _isLoading.value = true;
    final photos = await PhotoMockData.generateMockPhotosLazy();
    _allPhotos.value = photos;
    _updateGroupedPhotos();

    // 本地模式：所有图片已加载，无需加载更多
    _isApiMode = false;
    _hasMore = false;
    _currentPage = 0;
    _isLoading.value = false;

    print('✅ 已切换到本地懒加载模式');
  }

  /// 切换到本地Assets快速加载模式（无延迟）
  void switchToLocalModeFast() {
    print('🔄 切换到本地快速加载模式...');
    apiLoader.stopAutoLoading();
    
    _allPhotos.value = PhotoMockData.generateMockPhotos();
    _updateGroupedPhotos();

    // 本地模式：所有图片已加载，无需加载更多
    _isApiMode = false;
    _hasMore = false;
    _currentPage = 0;

    print('✅ 已切换到本地快速加载模式');
  }
  
  /// 切换自动滚动到新内容的设置
  void toggleAutoScrollToNew() {
    _autoScrollToNew.value = !_autoScrollToNew.value;
    print('🔄 自动滚动到新内容: ${_autoScrollToNew.value ? "开启" : "关闭"}');
  }

  /// 显示插入占位符在指定位置
  /// [groupKey] 组名
  /// [position] 位置
  void showInsertPlaceholder(String groupKey, int position) {
    print('🔵 显示插入占位符: 组="$groupKey", 位置=$position');
    
    // 取消之前的定时器，实现防抖
    _placeholderUpdateTimer?.cancel();
    
    // 使用防抖延迟更新，避免滑块拖动时频繁更新
    _placeholderUpdateTimer = Timer(const Duration(milliseconds: 100), () {
      // 使用 microtask 避免在 build 过程中更新状态
      Future.microtask(() {
        _insertPlaceholderGroup.value = groupKey;
        _insertPlaceholderPosition.value = position;
        
        // 强制刷新UI
        _groupedPhotos.refresh();
      });
    });
  }
  
  /// 隐藏插入占位符
  void hideInsertPlaceholder() {
    if (_insertPlaceholderGroup.value.isNotEmpty) {
      print('🔴 隐藏插入占位符');
      
      // 使用 scheduleMicrotask 避免在 build 过程中更新状态
      Future.microtask(() {
        _insertPlaceholderGroup.value = '';
        _insertPlaceholderPosition.value = -1;
        
        // 强制刷新UI
        _groupedPhotos.refresh();
      });
    }
  }
  
  /// 向指定组的指定位置插入图片
  /// [groupKey] 组名（如"2024年10月"）
  /// [position] 插入位置（0表示该组第一个位置）
  /// [photo] 要插入的照片
  void insertPhotoAt(String groupKey, int position, PhotoModel photo) {
    print('📥 向组 "$groupKey" 的位置 $position 插入图片: ${photo.path}');
    
    // 1. 先隐藏占位符
    hideInsertPlaceholder();
    
    // 2. 检查目标组是否存在
    if (!_groupedPhotos.containsKey(groupKey)) {
      print('❌ 目标组不存在: $groupKey');
      Get.snackbar('错误', '目标组不存在');
      return;
    }
    
    // 3. 获取目标组的照片列表
    final groupPhotos = _groupedPhotos[groupKey]!;
    
    // 4. 计算合适的日期：使用目标位置附近照片的日期
    DateTime targetDate;
    if (groupPhotos.isEmpty) {
      // 组为空，使用当前时间
      targetDate = DateTime.now();
    } else {
      // 使用目标位置的照片日期，确保插入后排序正确
      final targetPosition = position.clamp(0, groupPhotos.length);
      
      if (targetPosition >= groupPhotos.length) {
        // 插入到最后，使用最后一张照片的日期稍后一点
        targetDate = groupPhotos.last.date.add(const Duration(seconds: 1));
      } else if (targetPosition == 0) {
        // 插入到最前，使用第一张照片的日期稍早一点
        targetDate = groupPhotos.first.date.subtract(const Duration(seconds: 1));
      } else {
        // 插入到中间，使用前后两张照片日期的中间值
        final beforeDate = groupPhotos[targetPosition - 1].date;
        final afterDate = groupPhotos[targetPosition].date;
        final millisBetween = afterDate.millisecondsSinceEpoch - beforeDate.millisecondsSinceEpoch;
        targetDate = beforeDate.add(Duration(milliseconds: millisBetween ~/ 2));
      }
    }
    
    print('🕒 计算目标日期: $targetDate (组: $groupKey, 位置: $position)');
    
    // 5. 创建带有正确日期的新照片对象
    final photoWithDate = PhotoModel(
      path: photo.path,
      date: targetDate,
      title: photo.title,
      tags: photo.tags,
      isNetworkImage: photo.isNetworkImage,
    );
    
    // 6. 添加到总列表
    _allPhotos.add(photoWithDate);
    
    // 7. 重新分组（此时照片会自动按日期排序到正确位置）
    _updateGroupedPhotos();
    
    print('✅ 图片插入成功！当前总数: ${_allPhotos.length}');
  }
  
  /// 获取所有可用的组名列表
  List<String> get availableGroups {
    return _groupedPhotos.keys.toList();
  }
  
  /// 获取指定组的照片数量
  int getGroupPhotoCount(String groupKey) {
    return _groupedPhotos[groupKey]?.length ?? 0;
  }

  /// 设置选中的图片（用于在占位符中预览）
  /// [imagePath] 图片路径
  /// [isFromAssets] 是否来自 Assets
  void setSelectedImage(String imagePath, bool isFromAssets) {
    print('🖼️ 设置选中图片: $imagePath (Assets: $isFromAssets)');
    _selectedImagePath.value = imagePath;
    _isSelectedImageFromAssets.value = isFromAssets;
    
    // 强制刷新UI，更新占位符显示
    _groupedPhotos.refresh();
  }
  
  /// 清除选中的图片
  void clearSelectedImage() {
    if (_selectedImagePath.value.isNotEmpty) {
      print('🗑️ 清除选中图片');
      _selectedImagePath.value = '';
      _isSelectedImageFromAssets.value = true;
      
      // 强制刷新UI
      _groupedPhotos.refresh();
    }
  }

  /// 显示插入面板
  void showInsertPanel() {
    _isInsertPanelVisible.value = true;
    // 确保占位符可见
    scrollToPlaceholderIfNeeded();
  }

  /// 隐藏插入面板
  void hideInsertPanel() {
    _isInsertPanelVisible.value = false;
    // 隐藏面板时也清除选中的图片
    clearSelectedImage();
  }

  /// 切换插入面板显示状态
  void toggleInsertPanel() {
    _isInsertPanelVisible.value = !_isInsertPanelVisible.value;
    if (_isInsertPanelVisible.value) {
      scrollToPlaceholderIfNeeded();
    } else {
      hideInsertPlaceholder();
      clearSelectedImage();
    }
  }

  /// 计算占位符在滚动视图中的大致位置
  double calculatePlaceholderPosition() {
    if (!hasInsertPlaceholder) return 0;
    
    final groupKey = _insertPlaceholderGroup.value;
    final position = _insertPlaceholderPosition.value;
    
    // 估算：计算占位符之前有多少张图片
    int photosBeforePlaceholder = 0;
    
    final groupKeys = _groupedPhotos.keys.toList();
    final placeholderGroupIndex = groupKeys.indexOf(groupKey);
    
    // 累加占位符所在组之前所有组的照片数量
    for (int i = 0; i < placeholderGroupIndex; i++) {
      final key = groupKeys[i];
      photosBeforePlaceholder += _groupedPhotos[key]?.length ?? 0;
    }
    
    // 加上占位符在当前组内的位置
    photosBeforePlaceholder += position;
    
    // 估算每张照片的平均高度（假设每张照片约150像素，包括间距和组头部）
    // 这是一个粗略估算，实际高度取决于屏幕宽度和照片布局
    const double estimatedPhotoHeight = 150.0;
    
    return photosBeforePlaceholder * estimatedPhotoHeight;
  }

  /// 滚动到占位符位置（如果不可见）
  Future<void> scrollToPlaceholderIfNeeded() async {
    if (scrollController == null || !scrollController!.hasClients) {
      return;
    }
    
    if (!hasInsertPlaceholder) {
      return;
    }
    
    final placeholderPosition = calculatePlaceholderPosition();
    final currentScroll = scrollController!.offset;
    final viewportHeight = scrollController!.position.viewportDimension;
    
    // 插入面板高度（展开状态约200px）
    const double panelHeight = 200.0;
    
    // 计算占位符是否在可见区域内（考虑面板遮挡）
    final visibleTop = currentScroll;
    final visibleBottom = currentScroll + viewportHeight - panelHeight;
    
    // 如果占位符不在可见区域，滚动到该位置
    if (placeholderPosition < visibleTop || placeholderPosition > visibleBottom) {
      // 滚动到占位符位置，留出一些上边距
      final targetScroll = (placeholderPosition - 100).clamp(
        0.0, 
        scrollController!.position.maxScrollExtent,
      );
      
      await scrollController!.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void onClose() {
    // 取消占位符更新定时器
    _placeholderUpdateTimer?.cancel();
    
    // 停止API自动加载
    apiLoader.stopAutoLoading();
    super.onClose();
  }
}
