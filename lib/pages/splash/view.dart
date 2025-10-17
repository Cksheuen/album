import 'dart:async';
import 'package:album/pages/splash/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'controller.dart';
import '../../common/widgets/custom_scrollbar.dart';
import '../../common/widgets/photo_image.dart';
import '../../common/widgets/photo_loading_placeholder.dart';

class SplashPage extends GetView<SplashController> {
  SplashPage({super.key});

  // 显示全屏图片
  void _showFullScreenImage(
    BuildContext context,
    String imageAsset,
    String heroTag, {
    VoidCallback? onClosed,  // 添加关闭回调
  }) {
    print('显示全屏图片: $imageAsset, heroTag: $heroTag'); // 调试信息

    // 如果是从封面拉伸触发的（heroTag 以 'album_cover_' 开头），显示特殊提示
    final isFromCoverStretch = heroTag.startsWith('album_cover_');

    // 立即导航，使用 Hero 动画实现平滑过渡
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              actions: [
                if (isFromCoverStretch)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '封面图片',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    print('分享图片: $imageAsset');
                  },
                ),
              ],
            ),
            body: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: SmartImage(
                      path: imageAsset,
                      isNetwork: imageAsset.startsWith('http'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 400),
        reverseTransitionDuration: Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 使用淡入和缩放的组合动画
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    ).then((_) {
      // 全屏页面关闭时调用回调
      if (onClosed != null) {
        onClosed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final initialHeight = screenHeight * 0.25;

    // 创建 ScrollController 用于滚动控制
    final scrollController = ScrollController();
    
    // 设置新图片加载时的自动滚动回调
    controller.onNewPhotoLoaded = () {
      // 延迟一小段时间，确保UI已更新
      Future.delayed(Duration(milliseconds: 300), () {
        if (scrollController.hasClients) {
          // 滚动到底部
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    };

    return Scaffold(
      body: Obx(() {
        // 不再显示整体loading，直接显示页面
        // 每张图片会有独立的加载动画
        return _PullToRefreshWrapper(
          onRefresh: () async {
            await controller.refresh();
          },
          onStretchFullCover: (onClosed) {
            final coverImage =
                controller.coverPhoto?.path ??
                'assets/imgs/126351103_p0_master1200.jpg';
            // 使用与 SliverAppBar 中相同的 Hero tag，确保 Hero 动画正常工作
            final heroTag = 'album_cover_${controller.coverPhoto?.path ?? ''}';
            _showFullScreenImage(
              context, 
              coverImage, 
              heroTag,
              onClosed: onClosed,  // 传递 onClosed 回调
            );
          },
          child: CustomScrollbarWithIndicator(
            controller: scrollController,
            groupTitles: controller.groupTitles,
            onScrollPositionChanged: (scrollPercentage) {
              // 当滚动到底部90%时，触发加载更多
              if (scrollPercentage >= 0.9 &&
                  controller.hasMore &&
                  !controller.isLoadingMore) {
                controller.loadMorePhotos();
              }
            },
            child: CustomScrollView(
              controller: scrollController,
              // 添加滚动行为配置
              scrollBehavior: const MaterialScrollBehavior().copyWith(
                dragDevices: {
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.touch,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.unknown,
                },
              ),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  snap: false,
                  stretch: true, // 允许拉伸
                  // 禁用 SliverAppBar 的自动触发，使用我们自定义的下拉刷新逻辑
                  // onStretchTrigger: null,  // 不再使用
                  stretchTriggerOffset: 300.0, // 设置一个很大的值，实际上不会触发
                  expandedHeight: initialHeight,
                  flexibleSpace: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final top = constraints.biggest.height;
                      final isCollapsed =
                          top <=
                          kToolbarHeight + MediaQuery.of(context).padding.top;

                      return GestureDetector(
                        onDoubleTap: () {
                          // 双击滚动到顶部
                          scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: FlexibleSpaceBar(
                          title: AnimatedOpacity(
                            opacity: isCollapsed ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const Text(
                              '相册',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          titlePadding: const EdgeInsets.only(
                            left: 16,
                            bottom: 16,
                          ),
                          stretchModes: const [
                            StretchMode.zoomBackground,
                            StretchMode.blurBackground,
                          ],
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag:
                                    'album_cover_${controller.coverPhoto?.path ?? ''}',
                                child: controller.coverPhoto != null
                                    ? SmartImage(
                                        path: controller.coverPhoto!.path,
                                        isNetwork: controller
                                            .coverPhoto!
                                            .isNetworkImage,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue,
                                              Colors.purple,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.photo,
                                          size: 80,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isCollapsed)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '我的相册',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '共 ${controller.allPhotos.length} 张照片',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '轻拉刷新 · 继续下拉查看封面大图',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  actions: [
                    // 自动滚动到新内容的切换按钮
                    Obx(() => IconButton(
                      icon: Icon(
                        controller.autoScrollToNew 
                          ? Icons.arrow_downward 
                          : Icons.arrow_downward_outlined,
                        color: Colors.white,
                      ),
                      tooltip: controller.autoScrollToNew 
                        ? '自动滚动: 开启' 
                        : '自动滚动: 关闭',
                      onPressed: () {
                        controller.toggleAutoScrollToNew();
                      },
                    )),
                    // AppBar 右侧操作按钮
                    PopupMenuButton<SortType>(
                      icon: const Icon(Icons.sort, color: Colors.white),
                      onSelected: (SortType sortType) {
                        controller.changeSortType(sortType);
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: SortType.dateDesc,
                          child: Text('按日期降序'),
                        ),
                        const PopupMenuItem(
                          value: SortType.dateAsc,
                          child: Text('按日期升序'),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onSelected: (String value) {
                        if (value == 'clear') {
                          controller.clearFilter();
                        } else {
                          controller.filterByTag(value);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'clear',
                          child: Text('显示全部'),
                        ),
                        ...controller.allTags.map(
                          (tag) => PopupMenuItem(value: tag, child: Text(tag)),
                        ),
                      ],
                    ),
                    PopupMenuButton<GroupType>(
                      icon: const Icon(Icons.group_work, color: Colors.white),
                      onSelected: (GroupType groupType) {
                        controller.changeGroupType(groupType);
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem(
                          value: GroupType.year,
                          child: Text('按年分组'),
                        ),
                        const PopupMenuItem(
                          value: GroupType.month,
                          child: Text('按月分组'),
                        ),
                        const PopupMenuItem(
                          value: GroupType.day,
                          child: Text('按日分组'),
                        ),
                      ],
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: _VirtualizedGroupedGrid(
                    groupedPhotos: controller.groupedPhotos,
                    crossAxisCount: 4,
                    spacing: 2.0,
                    headerHeight: 40.0,
                    verticalGap: 8.0,
                    showLoadingPlaceholder: controller.hasLoadingPlaceholder,
                    onImageTap: (path) => _showFullScreenImage(
                      context,
                      path,
                      'album_photo_$path',
                    ),
                  ),
                ),
                // 加载更多指示器
                if (controller.isLoadingMore)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text(
                            '加载更多照片...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // 没有更多数据提示
                if (!controller.hasMore && controller.allPhotos.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: Text(
                        '已加载全部照片',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// header delegate removed: we now use manual layout with AnimatedPositioned

// 虚拟化分组网格：只渲染可视范围内的标题和图片，减少 Stack 子 widget 数量
class _VirtualizedGroupedGrid extends StatefulWidget {
  final Map<String, List<dynamic>> groupedPhotos;
  final int crossAxisCount;
  final double spacing;
  final double headerHeight;
  final double verticalGap;
  final void Function(String path) onImageTap;
  final bool showLoadingPlaceholder; // 是否显示加载占位符

  const _VirtualizedGroupedGrid({
    Key? key,
    required this.groupedPhotos,
    this.crossAxisCount = 4,
    this.spacing = 2.0,
    this.headerHeight = 40.0,
    this.verticalGap = 8.0,
    required this.onImageTap,
    this.showLoadingPlaceholder = false,
  }) : super(key: key);

  @override
  State<_VirtualizedGroupedGrid> createState() =>
      _VirtualizedGroupedGridState();
}

class _VirtualizedGroupedGridState extends State<_VirtualizedGroupedGrid> {
  // Scroll position from nearest Scrollable
  ScrollPosition? _position;
  double _viewportTop = 0.0;
  double _viewportBottom = 1000.0; // 初始设置较大的值，确保初次渲染

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // find primary Scrollable (CustomScrollView) and listen
    final scrollable = Scrollable.of(context);
    _position?.removeListener(_onScroll);
    _position = scrollable.position;
    _position?.addListener(_onScroll);

    // 确保在下一帧更新视口，避免初始白屏
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateViewport();
    });
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    _updateViewport();
  }

  void _updateViewport() {
    if (!mounted) return;

    final RenderObject? ro = context.findRenderObject();
    if (ro is RenderBox && _position != null) {
      try {
        // 获取屏幕尺寸
        final screenSize = MediaQuery.of(context).size;
        final screenHeight = screenSize.height;

        // 获取组件在屏幕坐标系中的位置
        final globalOffset = ro.localToGlobal(Offset.zero);

        // 计算视口范围（相对于组件内部坐标）
        double viewportTop = 0.0;
        double viewportBottom = screenHeight;

        // 如果组件顶部在屏幕上方，需要调整可视区域起始位置
        if (globalOffset.dy < 0) {
          viewportTop = -globalOffset.dy;
        }

        // 如果组件底部超出屏幕，需要调整可视区域结束位置
        final componentHeight = ro.size.height;
        if (globalOffset.dy + componentHeight > screenHeight) {
          viewportBottom =
              viewportTop +
              (screenHeight - globalOffset.dy.clamp(0.0, screenHeight));
        } else {
          viewportBottom = componentHeight;
        }

        // 确保视口范围合理
        viewportTop = viewportTop.clamp(0.0, componentHeight);
        viewportBottom = viewportBottom.clamp(viewportTop, componentHeight);

        if (mounted) {
          setState(() {
            _viewportTop = viewportTop;
            _viewportBottom = viewportBottom;
          });
        }
      } catch (e) {
        // 如果计算出错，使用安全的默认值
        if (mounted) {
          setState(() {
            _viewportTop = 0.0;
            _viewportBottom = MediaQuery.of(context).size.height;
          });
        }
      }
    }
  }

  bool _rectIntersectsViewport(double top, double height) {
    final double bottom = top + height;
    // 增加缓冲区，提前渲染即将进入视口的元素
    final double buffer = 200.0;
    final double expandedTop = _viewportTop - buffer;
    final double expandedBottom = _viewportBottom + buffer;
    return !(bottom < expandedTop || top > expandedBottom);
  }

  /// 构建照片项（支持加载占位符）
  Widget _buildPhotoItem(dynamic photo, String heroTag, double itemSize) {
    // 检测是否为加载占位符
    final bool isLoadingPlaceholder = photo.path == '__loading_placeholder__';
    
    if (isLoadingPlaceholder) {
      // 显示加载占位符
      return CompactPhotoLoadingPlaceholder(size: itemSize);
    }
    
    // 正常照片
    return InkWell(
      onTap: () => widget.onImageTap(photo.path),
      onLongPress: () {
        // keep existing behavior placeholder
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Hero(
          tag: heroTag,
          child: SmartImage(
            path: photo.path,
            isNetwork: photo.isNetworkImage,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果还没有正确的视口信息，使用屏幕尺寸作为初始视口
    if (_viewportBottom <= _viewportTop) {
      final screenHeight = MediaQuery.of(context).size.height;
      _viewportBottom = screenHeight;
    }
    
    // 🔥 修复：当内容变化时，确保视口信息更新
    // 使用 addPostFrameCallback 在下一帧更新，避免在 build 中调用 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateViewport();
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount = widget.crossAxisCount;
        final double spacing = widget.spacing;
        final double headerHeight = widget.headerHeight;
        final double verticalGap = widget.verticalGap;
        final double itemSize =
            (width - (crossAxisCount - 1) * spacing) / crossAxisCount;

        double yOffset = 0.0;
        final List<Widget> children = [];

        widget.groupedPhotos.forEach((groupTitle, photos) {
          // header
          final double headerTop = yOffset;
          if (_rectIntersectsViewport(headerTop, headerHeight)) {
            children.add(
              AnimatedPositioned(
                key: ValueKey('header_$groupTitle'),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                left: 0,
                top: headerTop,
                width: width,
                height: headerHeight,
                child: Container(
                  color: Colors.grey[100],
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    groupTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            );
          }

          yOffset += headerHeight;

          final int photoCount = photos.length;
          final int rows = (photoCount / crossAxisCount).ceil();
          final double groupHeight = rows * itemSize + (rows - 1) * spacing;

          // only iterate and add AnimatedPositioned for items that intersect viewport
          for (int i = 0; i < photoCount; i++) {
            final photo = photos[i];
            final int col = i % crossAxisCount;
            final int row = i ~/ crossAxisCount;
            final double left = col * (itemSize + spacing);
            final double top = yOffset + row * (itemSize + spacing);

            // If this item's rect isn't in viewport, skip creating widget to save cost.
            if (!_rectIntersectsViewport(top, itemSize)) continue;

            // 使用照片路径和日期作为唯一key，确保key在分组变化时保持稳定
            // 这样AnimatedPositioned才能正确追踪widget并应用过渡动画
            final uniqueKey =
                '${photo.path}_${photo.date.millisecondsSinceEpoch}';
            final heroTag = 'album_photo_$uniqueKey';

            children.add(
              AnimatedPositioned(
                key: ValueKey('photo_$uniqueKey'),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                left: left,
                top: top,
                width: itemSize,
                height: itemSize,
                child: Material(
                  color: Colors.transparent,
                  child: _buildPhotoItem(photo, heroTag, itemSize),
                ),
              ),
            );
          }

          yOffset += groupHeight + verticalGap;
        });

        // 🔥 添加加载占位符（绝对定位在最后一组的最后一位）
        if (widget.showLoadingPlaceholder && widget.groupedPhotos.isNotEmpty) {
          // 获取最后一组
          final lastGroupKey = widget.groupedPhotos.keys.last;
          final lastGroupPhotos = widget.groupedPhotos[lastGroupKey]!;
          
          // 计算最后一组的位置
          double lastGroupTop = 0.0;
          int processedGroups = 0;
          
          widget.groupedPhotos.forEach((groupTitle, photos) {
            if (processedGroups < widget.groupedPhotos.length - 1) {
              lastGroupTop += headerHeight; // header
              final int rows = (photos.length / crossAxisCount).ceil();
              lastGroupTop += rows * itemSize + (rows - 1) * spacing + verticalGap;
            }
            processedGroups++;
          });
          
          lastGroupTop += headerHeight; // 最后一组的 header
          
          // 计算占位符在网格中的位置（最后一组的下一个位置）
          final int lastGroupPhotoCount = lastGroupPhotos.length;
          final int placeholderIndex = lastGroupPhotoCount; // 占位符的索引
          final int placeholderCol = placeholderIndex % crossAxisCount;
          final int placeholderRow = placeholderIndex ~/ crossAxisCount;
          
          final double placeholderLeft = placeholderCol * (itemSize + spacing);
          final double placeholderTop = lastGroupTop + placeholderRow * (itemSize + spacing);
          
          // 只在可视区域内才渲染占位符
          if (_rectIntersectsViewport(placeholderTop, itemSize)) {
            children.add(
              AnimatedPositioned(
                key: const ValueKey('loading_placeholder'),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                left: placeholderLeft,
                top: placeholderTop,
                width: itemSize,
                height: itemSize,
                child: CompactPhotoLoadingPlaceholder(size: itemSize),
              ),
            );
          }
        }

        return SizedBox(
          height: yOffset,
          child: Stack(clipBehavior: Clip.none, children: children),
        );
      },
    );
  }
}

// 下拉刷新状态枚举
enum _PullRefreshStatus {
  idle,              // 空闲
  pulling,           // 下拉中
  canRefresh,        // 可以刷新
  canFullScreen,     // 可以全屏
  refreshing,        // 刷新中
  fullScreening,     // 全屏展示中
  completing,        // 完成中
}

// 自定义下拉包装器：监听滚动并根据下拉距离展示指示器，释放时根据阈值触发刷新或封面全屏
class _PullToRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final void Function(VoidCallback onClosed) onStretchFullCover;  // 修改签名，接收 onClosed 回调

  const _PullToRefreshWrapper({
    Key? key,
    required this.child,
    required this.onRefresh,
    required this.onStretchFullCover,
  }) : super(key: key);

  @override
  State<_PullToRefreshWrapper> createState() => _PullToRefreshWrapperState();
}

class _PullToRefreshWrapperState extends State<_PullToRefreshWrapper>
    with SingleTickerProviderStateMixin {
  static const double refreshThreshold = 80.0;
  static const double stretchThreshold = 150.0;

  double _pullDistance = 0.0;
  double _maxPullDistance = 0.0;  // 记录本次下拉的最大距离
  bool _isReleased = false;  // 标记用户是否已经松手
  bool _isOpened = false;    // 标记是否已经触发过全屏展示
  _PullRefreshStatus _status = _PullRefreshStatus.idle;
  late AnimationController _completionController;

  @override
  void initState() {
    super.initState();
    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _completionController.dispose();
    super.dispose();
  }

  // 根据下拉距离更新状态
  _PullRefreshStatus _calculateStatus(double distance) {
    if (_status == _PullRefreshStatus.refreshing || 
        _status == _PullRefreshStatus.fullScreening ||
        _status == _PullRefreshStatus.completing) {
      return _status; // 不在操作过程中更新状态
    }
    
    if (distance >= stretchThreshold) {
      return _PullRefreshStatus.canFullScreen;
    } else if (distance >= refreshThreshold) {
      return _PullRefreshStatus.canRefresh;
    } else if (distance > 0) {
      return _PullRefreshStatus.pulling;
    } else {
      return _PullRefreshStatus.idle;
    }
  }

  void _handleNotification(ScrollNotification notification) {
    // only consider vertical at top
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return;

    // 调试：打印关键信息
    if (notification is OverscrollNotification || 
        (notification is ScrollUpdateNotification && metrics.pixels < 0)) {
      print('🔍 Scroll metrics: extentBefore=${metrics.extentBefore}, pixels=${metrics.pixels}');
    }

    // if at top, negative pixels indicate overscroll (pull down)
    // 修改条件：允许在顶部附近（extentBefore <= 1.0）时也能触发
    if (metrics.extentBefore <= 1.0) {
      // ScrollEndNotification 作为兜底方案
      // 适用场景：某些设备或特殊情况下，距离减小检测可能失效
      // 例如：快速下拉松手、设备性能问题导致的帧丢失等
      if (notification is ScrollEndNotification) {
        // 场景1：兜底触发 - 还没触发过 且 有足够的下拉距离 且 没有打开全屏
        if (!_isReleased && !_isOpened && _maxPullDistance > 10) {
          print('🔚 ScrollEnd 兜底触发（距离检测可能失效）');
          _isReleased = true;
          _isOpened = true;
          _onRelease();
        } 
        // 场景2：清理残留 - 已经触发过释放，且回弹已经结束（距离接近0）
        else if (_isReleased && _pullDistance < 5.0) {
          print('🧹 ScrollEnd 清理残留状态: distance=${_pullDistance.toStringAsFixed(1)}, status=$_status');
          setState(() {
            _pullDistance = 0.0;
            _maxPullDistance = 0.0;
            // 如果当前是刷新中或全屏中，不要改变状态（让它们自然完成）
            // 只在其他状态时重置为 idle
            if (_status != _PullRefreshStatus.refreshing && 
                _status != _PullRefreshStatus.fullScreening &&
                _status != _PullRefreshStatus.completing) {
              _status = _PullRefreshStatus.idle;
            }
            // 重置标志，允许下次重新触发
            _isReleased = false;
            _isOpened = false;
          });
        } 
        else {
          print('📍 ScrollEnd: released=$_isReleased, opened=$_isOpened, maxDist=${_maxPullDistance.toStringAsFixed(1)} (跳过)');
        }
        return;
      }
      
      double newPull = _pullDistance;
      if (notification is OverscrollNotification) {
        // OverscrollNotification.overscroll is the delta scrolled; when pulling down it will be negative
        final double delta = notification.overscroll;
        if (delta < 0) {
          newPull = (_pullDistance + -delta).clamp(0.0, stretchThreshold * 2);
        }
      } else if (notification is ScrollUpdateNotification) {
        if (notification.metrics.pixels < 0) {
          newPull = (-notification.metrics.pixels).clamp(
            0.0,
            stretchThreshold * 2,
          );
        }
      }

      if (newPull != _pullDistance) {
        final newStatus = _calculateStatus(newPull);
        print('📊 Update: distance=${newPull.toStringAsFixed(1)}, oldStatus=$_status, newStatus=$newStatus');
        
        // 更新最大下拉距离
        if (newPull > _maxPullDistance) {
          _maxPullDistance = newPull;
          print('📈 Max pull distance updated: ${_maxPullDistance.toStringAsFixed(1)}');
          // 当距离增加时，说明用户正在下拉，重置所有标志
          _isReleased = false;
          _isOpened = false;  // ✅ 也重置 _isOpened，表示新的一次下拉
        }
        
        // 🔥 关键检测：如果距离开始减小（用户松手，开始回弹），立即触发释放逻辑
        // 只在未触发过的情况下触发一次
        if (!_isReleased && !_isOpened && newPull < _maxPullDistance && _maxPullDistance > 10) {
          print('🎯 检测到松手！distance=${newPull.toStringAsFixed(1)} < max=${_maxPullDistance.toStringAsFixed(1)}');
          _isReleased = true;
          _isOpened = true; // 标记已经触发过全屏展示
          // 立即触发释放，不等待回弹动画结束
          _onRelease();
          return;  // ✅ 直接返回，不更新状态
        }
        
        // 如果已经触发过释放，在回弹过程中只更新距离，不更新状态
        // 这样可以避免状态在 idle 和 pulling 之间反复切换
        // 但仍然可以根据距离来隐藏指示器
        if (_isReleased || _isOpened) {
          print('🔒 已触发释放，只更新距离 (distance=${newPull.toStringAsFixed(1)})');
          setState(() {
            _pullDistance = newPull;
            // 不更新 _status，保持当前状态
          });
          return;  // ✅ 不更新状态
        }
        
        setState(() {
          _pullDistance = newPull;
          _status = newStatus;
        });
        
        // 触觉反馈
        if (newStatus == _PullRefreshStatus.canRefresh && 
            _status != _PullRefreshStatus.canRefresh) {
          // 可以添加触觉反馈，如：HapticFeedback.mediumImpact();
        } else if (newStatus == _PullRefreshStatus.canFullScreen && 
                   _status != _PullRefreshStatus.canFullScreen) {
          // 可以添加触觉反馈，如：HapticFeedback.heavyImpact();
        }
      }
    } else {
      // not at top, reset all pull-related state
      if (_pullDistance != 0.0 || _maxPullDistance != 0.0) {
        print('🔄 离开顶部，重置所有下拉状态');
        setState(() {
          _pullDistance = 0.0;
          _maxPullDistance = 0.0;
          _status = _PullRefreshStatus.idle;
          // 重置标志，允许下次重新触发
          _isReleased = false;
          _isOpened = false;
        });
      }
    }
  }

  void _onRelease() async {
    final d = _pullDistance;
    final maxD = _maxPullDistance;  // 使用记录的最大距离
    
    // 调试日志
    print('🔍 _onRelease: current=$d, max=$maxD, status=$_status, canFullScreen=${_status == _PullRefreshStatus.canFullScreen}, maxReached=${maxD >= stretchThreshold}');
    
    if (_status == _PullRefreshStatus.refreshing || 
        _status == _PullRefreshStatus.fullScreening) {
      _maxPullDistance = 0.0;  // 重置最大距离
      return;
    }

    // 使用最大下拉距离或当前状态判断
    if (_status == _PullRefreshStatus.canFullScreen || maxD >= stretchThreshold) {
      print('✅ Triggering FULL SCREEN! (maxDistance=${maxD.toStringAsFixed(1)}px >= ${stretchThreshold}px)');
      
      // 先立即重置状态（隐藏指示器），然后触发全屏动画
      // 这样可以避免指示器显示和全屏动画之间的视觉冲突
      if (mounted) {
        setState(() {
          _status = _PullRefreshStatus.idle;
          _pullDistance = 0.0;
          // ❌ 不要在这里清零 _maxPullDistance！
          // 保持 _maxPullDistance 的值，直到关闭全屏或离开顶部时才清零
          // 这样可以防止回弹过程中的距离变化被误认为是新的下拉
        });
      }
      
      // 使用微任务立即触发全屏，避免帧延迟
      scheduleMicrotask(() {
        widget.onStretchFullCover(() {
          // 全屏页面关闭时的回调，完全重置所有下拉相关状态
          if (mounted) {
            setState(() {
              _isOpened = false;
              _maxPullDistance = 0.0;  // 重置最大距离，防止兜底触发
              _pullDistance = 0.0;
              _status = _PullRefreshStatus.idle;  // ✅ 重置状态，隐藏指示器
              print('🔄 全屏页面已关闭，完全重置状态');
            });
          }
        });
      });
      
      return;
    }

    if (_status == _PullRefreshStatus.canRefresh || maxD >= refreshThreshold) {
      print('✅ Triggering REFRESH (maxDistance=${maxD.toStringAsFixed(1)}px >= ${refreshThreshold}px)');
      setState(() {
        _status = _PullRefreshStatus.refreshing;
        // 不在这里重置 _isReleased，让它在下次下拉时自然重置
        // 也不清零 _maxPullDistance，防止回弹过程中重复触发
      });
      try {
        await widget.onRefresh();
      } finally {
        // 刷新完成后，显示短暂的完成提示
        if (mounted) {
          setState(() {
            _status = _PullRefreshStatus.completing;
            _pullDistance = 0.0;
            // ✅ 在刷新完成后才清零 _maxPullDistance
            _maxPullDistance = 0.0;
          });
          // 延迟后恢复到 idle
          _completionController.forward(from: 0.0).then((_) {
            if (mounted) {
              setState(() {
                _status = _PullRefreshStatus.idle;
              });
            }
          });
        }
      }
      return;
    }

    // otherwise, just reset
    print('⚪ No action triggered, resetting (maxDistance=${maxD.toStringAsFixed(1)}px < ${refreshThreshold}px)');
    setState(() {
      _pullDistance = 0.0;
      // ⚠️ 不要在这里清零 _maxPullDistance！
      // 保持 _maxPullDistance 的值，这样回弹过程中的距离变化不会被误认为是新的下拉
      // _maxPullDistance 会在 ScrollEnd 清理残留时被重置
      _status = _PullRefreshStatus.idle;
      // _isReleased 保持为 true，这样 ScrollEnd 可以检测到并清理残留
    });
  }

  @override
  Widget build(BuildContext context) {
    // 计算进度
    final double refreshProgress = (_pullDistance / refreshThreshold).clamp(0.0, 1.0);
    final double fullScreenProgress = _pullDistance >= refreshThreshold 
        ? ((_pullDistance - refreshThreshold) / (stretchThreshold - refreshThreshold)).clamp(0.0, 1.0)
        : 0.0;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _handleNotification(notification);
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          // Top indicator with enhanced visual feedback
          Positioned(
            // 使用 viewPadding.top 以避开刘海/灵动岛等安全区
            top: MediaQuery.of(context).viewPadding.top + 8,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: _shouldUseAnimatedSwitcher()
                    ? AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: _buildIndicator(refreshProgress, fullScreenProgress),
                      )
                    : _buildIndicator(refreshProgress, fullScreenProgress),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 判断是否应该使用 AnimatedSwitcher
  // 下拉过程中的状态切换不使用 AnimatedSwitcher，避免闪烁
  bool _shouldUseAnimatedSwitcher() {
    // 下拉相关的状态直接更新，不要动画
    const pullingStates = {
      _PullRefreshStatus.pulling,
      _PullRefreshStatus.canRefresh,
      _PullRefreshStatus.canFullScreen,
    };
    
    // 如果是下拉状态，不使用 AnimatedSwitcher
    return !pullingStates.contains(_status);
  }

  // 根据状态构建不同的指示器
  Widget _buildIndicator(double refreshProgress, double fullScreenProgress) {
    // 使用状态值和时间戳的组合作为 key，确保唯一性
    final key = ValueKey('${_status.toString()}_${_pullDistance.toStringAsFixed(1)}');
    
    switch (_status) {
      case _PullRefreshStatus.idle:
        return SizedBox.shrink(key: key);
        
      case _PullRefreshStatus.pulling:
        // 下拉中 - 显示刷新进度
        return Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  value: refreshProgress,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '下拉刷新',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
        
      case _PullRefreshStatus.canRefresh:
        // 可以刷新 - 显示即将全屏的提示
        return Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '松开刷新',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (fullScreenProgress > 0)
                    SizedBox(
                      width: 60,
                      height: 2,
                      child: LinearProgressIndicator(
                        value: fullScreenProgress,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                ],
              ),
              if (fullScreenProgress > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '继续下拉',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        );
        
      case _PullRefreshStatus.canFullScreen:
        // 可以全屏
        return Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fullscreen, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                '松开查看封面大图',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
        
      case _PullRefreshStatus.refreshing:
        // 刷新中 - 但如果下拉距离已经回弹到接近0，就隐藏指示器
        // 这样可以避免在回弹过程中指示器一直显示
        if (_pullDistance < 5.0) {
          return SizedBox.shrink(key: key);
        }
        return Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '刷新中...',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
        
      case _PullRefreshStatus.fullScreening:
        // 全屏展示中
        return Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fullscreen, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                '正在打开...',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
        
      case _PullRefreshStatus.completing:
        // 完成中
        return Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                '完成',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
    }
  }
}
