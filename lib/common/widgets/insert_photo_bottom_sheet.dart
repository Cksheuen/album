import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/photo_model.dart';
import '../../common/utils/assets_image_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// 底部弹出的插入图片控制面板
/// 允许用户在不遮挡相册内容的情况下选择插入位置和图片
class InsertPhotoBottomSheet extends StatefulWidget {
  final List<String> availableGroups;
  final Function(String groupKey, int position, PhotoModel photo) onInsert;
  final Function(String groupKey, int position)? onPositionChanged; // 位置变化时的回调
  final int Function(String groupKey) getGroupPhotoCount;

  const InsertPhotoBottomSheet({
    Key? key,
    required this.availableGroups,
    required this.onInsert,
    this.onPositionChanged,
    required this.getGroupPhotoCount,
  }) : super(key: key);

  @override
  State<InsertPhotoBottomSheet> createState() => _InsertPhotoBottomSheetState();
}

class _InsertPhotoBottomSheetState extends State<InsertPhotoBottomSheet> {
  String? selectedGroup;
  int selectedPosition = 0;
  String? selectedImagePath;
  bool isFromAssets = true;
  bool isExpanded = false; // 控制面板是否展开显示图片选择
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.availableGroups.isNotEmpty) {
      selectedGroup = widget.availableGroups.first;
      // 延迟通知初始位置，避免在 build 过程中更新状态
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyPositionChanged();
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
      Get.snackbar('错误', '选择图片失败: $e');
    }
  }

  void _pickFromAssets() {
    final availableImages = AssetsImageManager.getAllImagePaths();
    
    // 使用底部弹出的方式选择图片
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 顶部拖拽指示器
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '选择图片',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 网格视图
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
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
                      Get.back();
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
                            Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                            ),
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
      isDismissible: true,
      enableDrag: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupPhotoCount = selectedGroup != null 
        ? widget.getGroupPhotoCount(selectedGroup!)
        : 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖拽指示器
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '插入图片到相册',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // 内容区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 选择分组
                Row(
                  children: [
                    const Icon(Icons.folder_outlined, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '目标分组',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedGroup,
                    isExpanded: true,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    items: widget.availableGroups.map((group) {
                      return DropdownMenuItem(
                        value: group,
                        child: Text(group),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedGroup = value;
                        selectedPosition = 0; // 重置位置
                        _notifyPositionChanged();
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 选择位置
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '插入位置',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selectedPosition == groupPhotoCount 
                            ? '末尾' 
                            : '第 ${selectedPosition + 1} 位',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.blue[100],
                    thumbColor: Colors.blue,
                    overlayColor: Colors.blue.withOpacity(0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: selectedPosition.toDouble(),
                    min: 0,
                    max: groupPhotoCount.toDouble(),
                    divisions: groupPhotoCount > 0 ? groupPhotoCount : 1,
                    label: selectedPosition == groupPhotoCount 
                        ? '末尾' 
                        : '位置 ${selectedPosition + 1}',
                    onChanged: (value) {
                      setState(() {
                        selectedPosition = value.toInt();
                        _notifyPositionChanged();
                      });
                    },
                  ),
                ),
                Text(
                  '将插入到该组的第 ${selectedPosition + 1} 位（共 $groupPhotoCount 张）',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                
                const SizedBox(height: 20),
                
                // 选择图片
                Row(
                  children: [
                    const Icon(Icons.image_outlined, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '选择图片',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // 图片选择按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromAssets,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Assets图片'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isFromAssets && selectedImagePath != null 
                                ? Colors.blue 
                                : Colors.grey[300]!,
                            width: isFromAssets && selectedImagePath != null ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('设备相册'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: !isFromAssets && selectedImagePath != null 
                                ? Colors.blue 
                                : Colors.grey[300]!,
                            width: !isFromAssets && selectedImagePath != null ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 图片预览
                if (selectedImagePath != null)
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          isFromAssets
                              ? Image.asset(selectedImagePath!, fit: BoxFit.cover)
                              : Image.file(File(selectedImagePath!), fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // 底部按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: selectedImagePath == null || selectedGroup == null
                            ? null
                            : () {
                                // 创建新的PhotoModel
                                final photo = PhotoModel(
                                  path: selectedImagePath!,
                                  date: DateTime.now(),
                                  title: '插入的图片',
                                  tags: ['手动插入'],
                                  isNetworkImage: !isFromAssets,
                                );
                                
                                widget.onInsert(selectedGroup!, selectedPosition, photo);
                                Get.back();
                                
                                // 延迟显示成功提示，避免与关闭动画冲突
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  Get.snackbar(
                                    '成功',
                                    '图片正在插入到 "$selectedGroup" 的第 ${selectedPosition + 1} 位',
                                    snackPosition: SnackPosition.TOP,
                                    backgroundColor: Colors.green[600],
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 2),
                                  );
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('确认插入'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
