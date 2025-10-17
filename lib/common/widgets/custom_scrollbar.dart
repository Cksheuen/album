import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 自定义滚动条（带分组指示器）
/// 完全使用 GetX 响应式设计
class CustomScrollbarWithIndicator extends StatelessWidget {
  final ScrollController controller;
  final Widget child;
  final List<String> groupTitles;
  final Function(double)? onScrollPositionChanged;

  const CustomScrollbarWithIndicator({
    Key? key,
    required this.controller,
    required this.child,
    required this.groupTitles,
    this.onScrollPositionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scrollbarController = Get.put(
      _ScrollbarController(
        scrollController: controller,
        onScrollPositionChanged: onScrollPositionChanged,
      ),
      tag: controller.hashCode.toString(),
    );

    // 更新 groupTitles（每次 build 时都会更新）
    scrollbarController.updateGroupTitles(groupTitles);

    return Stack(
      children: [
        child,
        Obx(() => _buildScrollbar(context, scrollbarController)),
        Obx(() => _buildIndicator(scrollbarController)),
      ],
    );
  }

  Widget _buildScrollbar(BuildContext context, _ScrollbarController ctrl) {
    if (!ctrl.showScrollbar.value) return SizedBox.shrink();

    final screenHeight = MediaQuery.of(context).size.height;
    final scrollbarHeight = screenHeight * 0.6;

    return Positioned(
      right: 0,
      top: (screenHeight - scrollbarHeight) / 2,
      child: GestureDetector(
        onVerticalDragStart: (details) => ctrl.onDragStart(details),
        onVerticalDragUpdate: (details) => ctrl.onDragUpdate(details),
        onVerticalDragEnd: (details) => ctrl.onDragEnd(),
        child: MouseRegion(
          onEnter: (_) => ctrl.onMouseEnter(),
          onExit: (_) => ctrl.onMouseExit(),
          child: AnimatedOpacity(
            // 滚动时显示，静止时隐藏
            opacity: ctrl.isScrolling.value || ctrl.isHovering.value || ctrl.isDragging.value ? 1.0 : 0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: Container(
              width: ctrl.isHovering.value || ctrl.isDragging.value ? 20 : 8,
              height: scrollbarHeight,
              padding: EdgeInsets.only(right: 2),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    // 滑块
                    AnimatedPositioned(
                      duration: ctrl.isDragging.value
                          ? Duration.zero
                          : Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      left: 0,
                      right: 0,
                      top: ctrl.thumbPosition.value *
                          (scrollbarHeight - ctrl.thumbHeight.value),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        height: ctrl.thumbHeight.value,
                        decoration: BoxDecoration(
                          color: ctrl.isHovering.value || ctrl.isDragging.value
                              ? Colors.grey.withOpacity(0.8)
                              : Colors.grey.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(_ScrollbarController ctrl) {
    if (!ctrl.showIndicator.value) return SizedBox.shrink();

    return Positioned(
      right: 60,
      top: MediaQuery.of(Get.context!).size.height / 2 - 30,
      child: AnimatedScale(
        scale: ctrl.showIndicator.value ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: ctrl.showIndicator.value ? 1.0 : 0.0,
          duration: Duration(milliseconds: 200),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              ctrl.currentGroupTitle.value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollbarController extends GetxController {
  final ScrollController scrollController;
  final Function(double)? onScrollPositionChanged;

  _ScrollbarController({
    required this.scrollController,
    this.onScrollPositionChanged,
  });

  final RxBool isDragging = false.obs;
  final RxBool isHovering = false.obs;
  final RxBool isScrolling = false.obs;  // ✅ 添加滚动状态
  final RxBool showScrollbar = false.obs;
  final RxBool showIndicator = false.obs;
  final RxString currentGroupTitle = ''.obs;
  final RxDouble scrollPosition = 0.0.obs;
  final RxDouble thumbPosition = 0.0.obs;
  final RxDouble thumbHeight = 48.0.obs;
  final RxDouble maxScrollExtent = 0.0.obs;
  final RxList<String> groupTitles = <String>[].obs;

  // 记录拖拽开始时的偏移量
  double _dragStartOffset = 0.0;
  
  // 滚动停止计时器
  Timer? _scrollTimer;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    Future.delayed(Duration.zero, _updateScrollMetrics);
  }

  @override
  void onClose() {
    _scrollTimer?.cancel();
    scrollController.removeListener(_onScroll);
    super.onClose();
  }

  /// 鼠标进入滚动条区域
  void onMouseEnter() {
    isHovering.value = true;
    showIndicator.value = true;  // 悬停时显示组名
  }

  /// 鼠标离开滚动条区域
  void onMouseExit() {
    isHovering.value = false;
    if (!isDragging.value) {
      showIndicator.value = false;  // 不拖拽时隐藏组名
    }
  }

  /// 更新分组标题列表
  void updateGroupTitles(List<String> newTitles) {
    if (groupTitles.length != newTitles.length ||
        !_listsEqual(groupTitles, newTitles)) {
      groupTitles.value = newTitles;
      // 重新计算当前分组
      _updateCurrentGroup(scrollPosition.value);
      // 重新计算滚动条高度（因为内容可能变化）
      Future.delayed(Duration(milliseconds: 100), _updateScrollMetrics);
    }
  }

  /// 比较两个列表是否相等
  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void _updateScrollMetrics() {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;
    maxScrollExtent.value = position.maxScrollExtent;
    showScrollbar.value = maxScrollExtent.value > 0;

    final viewportRatio =
        position.viewportDimension /
        (position.maxScrollExtent + position.viewportDimension);
    thumbHeight.value =
        (viewportRatio * 0.6 * MediaQuery.of(Get.context!).size.height).clamp(
          48.0,
          200.0,
        );

    if (maxScrollExtent.value > 0) {
      scrollPosition.value = position.pixels / maxScrollExtent.value;
      // thumbPosition 应该考虑滑块高度，避免超出边界
      // 当滚动到底部时，滑块应该在 (scrollbarHeight - thumbHeight) 的位置
      thumbPosition.value = scrollPosition.value;
      _updateCurrentGroup(scrollPosition.value);
    }
  }

  void _onScroll() {
    if (isDragging.value) return;
    
    // 标记正在滚动
    isScrolling.value = true;
    
    // 取消之前的计时器
    _scrollTimer?.cancel();
    
    // 设置新的计时器：500ms 后认为滚动停止
    _scrollTimer = Timer(Duration(milliseconds: 500), () {
      isScrolling.value = false;
    });
    
    _updateScrollMetrics();

    if (onScrollPositionChanged != null && scrollController.hasClients) {
      final position = scrollController.position;
      final percentage = maxScrollExtent.value > 0
          ? position.pixels / maxScrollExtent.value
          : 0.0;
      onScrollPositionChanged!(percentage);
    }
  }

  void _updateCurrentGroup(double percentage) {
    if (groupTitles.isEmpty) return;
    final index = (percentage * groupTitles.length)
        .clamp(0, groupTitles.length - 1)
        .toInt();
    currentGroupTitle.value = groupTitles[index];
  }

  void onDragStart(DragStartDetails details) {
    isDragging.value = true;
    showIndicator.value = true;  // 拖拽时显示组名

    // 记录拖拽开始时，触摸点在滑块内的相对位置
    final screenHeight = MediaQuery.of(Get.context!).size.height;
    final scrollbarHeight = screenHeight * 0.6;
    final thumbTop = thumbPosition.value * (scrollbarHeight - thumbHeight.value);

    // 计算触摸点相对于滑块顶部的偏移
    _dragStartOffset = details.localPosition.dy - thumbTop;
  }

  void onDragUpdate(DragUpdateDetails details) {
    if (!scrollController.hasClients) return;

    final screenHeight = MediaQuery.of(Get.context!).size.height;
    final scrollbarHeight = screenHeight * 0.6;

    // 计算滑块顶部应该在的位置（触摸点 - 初始偏移）
    final thumbTop = details.localPosition.dy - _dragStartOffset;

    // 限制滑块位置，确保不超出边界（考虑滑块高度）
    final maxThumbTop = scrollbarHeight - thumbHeight.value;
    final clampedThumbTop = thumbTop.clamp(0.0, maxThumbTop);

    // 计算滚动百分比
    final newPosition = maxThumbTop > 0
        ? (clampedThumbTop / maxThumbTop).clamp(0.0, 1.0)
        : 0.0;

    thumbPosition.value = newPosition;
    scrollPosition.value = newPosition;

    final targetPixels = newPosition * maxScrollExtent.value;
    scrollController.jumpTo(targetPixels);

    _updateCurrentGroup(newPosition);
  }

  void onDragEnd() {
    isDragging.value = false;
    // 拖拽结束后延迟隐藏组名指示器
    Future.delayed(Duration(milliseconds: 300), () {
      if (!isDragging.value && !isHovering.value) {
        showIndicator.value = false;
      }
    });
  }
}
