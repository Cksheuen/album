import 'package:album/pages/splash/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'controller.dart';
import '../../common/widgets/custom_scrollbar.dart';
import '../../common/widgets/photo_image.dart';

class SplashPage extends GetView<SplashController> {
  SplashPage({super.key});

  // 显示全屏图片
  void _showFullScreenImage(
    BuildContext context,
    String imageAsset,
    String heroTag,
  ) {
    print('显示全屏图片: $imageAsset, heroTag: $heroTag'); // 调试信息

    // 如果是从封面拉伸触发的，显示特殊提示
    final isFromCoverStretch = heroTag == 'album_cover_stretch';

    // 使用 post-frame callback 来避免在 build 过程中调用 Navigator
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
                  onPressed: () => Navigator.of(context).pop(),
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
          transitionDuration: Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final initialHeight = screenHeight * 0.25;

    // 创建 ScrollController 用于滚动控制
    final scrollController = ScrollController();

    return Scaffold(
      body: Obx(() {
        // 不再显示整体loading，直接显示页面
        // 每张图片会有独立的加载动画
        return _PullToRefreshWrapper(
          onRefresh: () async {
            await controller.refresh();
          },
          onStretchFullCover: () {
            final coverImage =
                controller.coverPhoto?.path ??
                'assets/imgs/126351103_p0_master1200.jpg';
            _showFullScreenImage(context, coverImage, 'album_cover_stretch');
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
                  onStretchTrigger: () async {
                    final coverImage =
                        controller.coverPhoto?.path ??
                        'assets/imgs/126351103_p0_master1200.jpg';
                    _showFullScreenImage(
                      context,
                      coverImage,
                      'album_cover_stretch',
                    );
                    return;
                  },
                  stretchTriggerOffset: 150.0,
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

  const _VirtualizedGroupedGrid({
    Key? key,
    required this.groupedPhotos,
    this.crossAxisCount = 4,
    this.spacing = 2.0,
    this.headerHeight = 40.0,
    this.verticalGap = 8.0,
    required this.onImageTap,
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

  @override
  Widget build(BuildContext context) {
    // 如果还没有正确的视口信息，使用屏幕尺寸作为初始视口
    if (_viewportBottom <= _viewportTop) {
      final screenHeight = MediaQuery.of(context).size.height;
      _viewportBottom = screenHeight;
    }

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
                  child: InkWell(
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
                  ),
                ),
              ),
            );
          }

          yOffset += groupHeight + verticalGap;
        });

        return SizedBox(
          height: yOffset,
          child: Stack(clipBehavior: Clip.none, children: children),
        );
      },
    );
  }
}

// 自定义下拉包装器：监听滚动并根据下拉距离展示指示器，释放时根据阈值触发刷新或封面全屏
class _PullToRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final VoidCallback onStretchFullCover;

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
  bool _isRefreshing = false;
  bool _isPerformingStretch = false;

  void _handleNotification(ScrollNotification notification) {
    // only consider vertical at top
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return;

    // if at top, negative pixels indicate overscroll (pull down)
    if (metrics.extentBefore == 0) {
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
      } else if (notification is ScrollEndNotification) {
        // release
        _onRelease();
      }

      if (newPull != _pullDistance) {
        setState(() {
          _pullDistance = newPull;
        });
      }
    } else {
      // not at top, reset
      if (_pullDistance != 0.0) {
        setState(() {
          _pullDistance = 0.0;
        });
      }
    }
  }

  void _onRelease() async {
    final d = _pullDistance;
    if (_isRefreshing || _isPerformingStretch) return;

    if (d >= stretchThreshold) {
      setState(() {
        _isPerformingStretch = true;
      });
      try {
        widget.onStretchFullCover();
      } finally {
        if (mounted) {
          setState(() {
            _isPerformingStretch = false;
            _pullDistance = 0.0;
          });
        }
      }
      return;
    }

    if (d >= refreshThreshold) {
      setState(() {
        _isRefreshing = true;
      });
      try {
        await widget.onRefresh();
      } finally {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
            _pullDistance = 0.0;
          });
        }
      }
      return;
    }

    // otherwise, just reset
    setState(() {
      _pullDistance = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // indicator visibility/size: map pullDistance to 0..1 for refreshThreshold
    final double progress = (_pullDistance / refreshThreshold).clamp(0.0, 1.0);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _handleNotification(notification);
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          // Top indicator
          Positioned(
            // 使用 viewPadding.top 以避开刘海/灵动岛等安全区
            top: MediaQuery.of(context).viewPadding.top + 8,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isRefreshing
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : progress > 0
                      ? SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            value: progress,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
