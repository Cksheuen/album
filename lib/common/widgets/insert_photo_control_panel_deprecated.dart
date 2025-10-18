// ============================================================================
// ⚠️ 已废弃 (DEPRECATED) ⚠️
// ============================================================================
// 
// 此文件已被 insert_photo_toolbar.dart 替代
// 
// 废弃原因：
// 1. 控制面板过于复杂，包含组选择、位置滑块等控件
// 2. 引入拖动占位符功能后，位置调整可以直接通过拖动完成
// 3. 新的简化工具栏只需要：选择图片 + 确认插入 两个按钮
// 
// 保留此文件用于：
// - 代码参考
// - 历史记录
// - 必要时的回退方案
// 
// 相关文档：
// - FEATURE_DRAGGABLE_INSERT_PLACEHOLDER.md
// - FEATURE_SIMPLIFIED_TOOLBAR.md
// 
// 最后更新：2025-10-18
// ============================================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/photo_model.dart';
import '../../common/utils/assets_image_manager.dart';
import 'package:image_picker/image_picker.dart';

/// 固定在底部的插入控制面板(无遮罩层）
/// 使用 AnimatedContainer 实现展开/收起动画
@Deprecated('使用 InsertPhotoToolbar 替代。此组件过于复杂，已被简化工具栏取代。')
class InsertPhotoControlPanel extends StatefulWidget {
  final List<String> availableGroups;
  final Function(String groupKey, int position, PhotoModel photo) onInsert;
  final Function(String groupKey, int position)? onPositionChanged;
  final int Function(String groupKey) getGroupPhotoCount;
  final VoidCallback? onClose;
  final Function(bool isVisible)? onVisibilityChanged;
  final bool isVisible; // 外部控制是否展开

  const InsertPhotoControlPanel({
    Key? key,
    required this.availableGroups,
    required this.onInsert,
    this.onPositionChanged,
    required this.getGroupPhotoCount,
    this.onClose,
    this.onVisibilityChanged,
    this.isVisible = false, // 默认收起
  }) : super(key: key);

  @override
  State<InsertPhotoControlPanel> createState() => _InsertPhotoControlPanelState();
}

class _InsertPhotoControlPanelState extends State<InsertPhotoControlPanel> {
  String? selectedGroup;
  int selectedPosition = 0;
  String? selectedImagePath;
  bool isFromAssets = true;
  late bool isExpanded; // 面板展开状态
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    isExpanded = widget.isVisible; // 使用外部传入的初始状态
    if (widget.availableGroups.isNotEmpty) {
      selectedGroup = widget.availableGroups.first;
      // 延迟通知初始位置和可见性
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyPositionChanged();
        widget.onVisibilityChanged?.call(isExpanded);
      });
    }
  }

  @override
  void didUpdateWidget(InsertPhotoControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当外部控制的可见性改变时，同步内部状态
    if (oldWidget.isVisible != widget.isVisible && isExpanded != widget.isVisible) {
      setState(() {
        isExpanded = widget.isVisible;
      });
    }
  }

  void _notifyPositionChanged() {
    if (widget.onPositionChanged != null && selectedGroup != null) {
      widget.onPositionChanged!(selectedGroup!, selectedPosition);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          selectedImagePath = image.path;
          isFromAssets = false;
        });
      }
    } catch (e) {
      Get.snackbar('错误', '选择图片失败: $e', snackPosition: SnackPosition.TOP);
    }
  }

  void _pickFromAssets() {
    final availableImages = AssetsImageManager.getAllImagePaths();
    
    // 使用全屏对话框选择图片
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '选择图片',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: availableImages.length,
                  itemBuilder: (context, index) {
                    final imagePath = availableImages[index];
                    final isSelected = selectedImagePath == imagePath;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedImagePath = imagePath;
                          isFromAssets = true;
                        });
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(imagePath, fit: BoxFit.cover),
                              if (isSelected)
                                Container(
                                  color: Colors.blue.withOpacity(0.3),
                                  child: const Center(
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupPhotoCount = selectedGroup != null 
        ? widget.getGroupPhotoCount(selectedGroup!)
        : 0;

    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: isExpanded ? 200 : 50,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
      child: Column(
        children: [
          // 标题栏（始终可见）
          GestureDetector(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
                // 通知可见性变化
                widget.onVisibilityChanged?.call(isExpanded);
              });
            },
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '插入图片',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  if (selectedImagePath != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '已选择',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                    tooltip: '关闭',
                  ),
                ],
              ),
            ),
          ),
          
          // 展开内容
          if (isExpanded)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 分组和位置选择
                    Row(
                      children: [
                        // 分组选择
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '分组',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<String>(
                                  value: selectedGroup,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: widget.availableGroups.map((group) {
                                    return DropdownMenuItem(
                                      value: group,
                                      child: Text(
                                        group,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedGroup = value;
                                      selectedPosition = 0;
                                      _notifyPositionChanged();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 位置显示
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '位置',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Text(
                                  selectedPosition == groupPhotoCount 
                                      ? '末尾' 
                                      : '第${selectedPosition + 1}位',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 位置滑块
                    Row(
                      children: [
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.blue,
                              inactiveTrackColor: Colors.blue[100],
                              thumbColor: Colors.blue,
                              overlayColor: Colors.blue.withOpacity(0.2),
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                            ),
                            child: Slider(
                              value: selectedPosition.toDouble(),
                              min: 0,
                              max: groupPhotoCount.toDouble(),
                              divisions: groupPhotoCount > 0 ? groupPhotoCount : 1,
                              onChanged: (value) {
                                setState(() {
                                  selectedPosition = value.toInt();
                                  _notifyPositionChanged();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 图片选择按钮
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickFromAssets,
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: const Text('Assets', style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickFromGallery,
                            icon: const Icon(Icons.photo_camera, size: 18),
                            label: const Text('相册', style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: selectedImagePath == null || selectedGroup == null
                              ? null
                              : () {
                                  final photo = PhotoModel(
                                    path: selectedImagePath!,
                                    date: DateTime.now(),
                                    title: '插入的图片',
                                    tags: ['手动插入'],
                                    isNetworkImage: !isFromAssets,
                                  );
                                  
                                  widget.onInsert(selectedGroup!, selectedPosition, photo);
                                  
                                  Get.snackbar(
                                    '成功',
                                    '图片已插入到 "$selectedGroup" 的第 ${selectedPosition + 1} 位',
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: Colors.green[600],
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 2),
                                  );
                                },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('插入', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      ), // SafeArea 闭合
    );
  }
}
