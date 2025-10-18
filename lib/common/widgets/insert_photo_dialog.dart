import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/photo_model.dart';
import '../../common/utils/assets_image_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// 插入图片对话框
/// 允许用户选择组、位置和图片来源
class InsertPhotoDialog extends StatefulWidget {
  final List<String> availableGroups;
  final Function(String groupKey, int position, PhotoModel photo) onInsert;
  final int Function(String groupKey) getGroupPhotoCount;

  const InsertPhotoDialog({
    Key? key,
    required this.availableGroups,
    required this.onInsert,
    required this.getGroupPhotoCount,
  }) : super(key: key);

  @override
  State<InsertPhotoDialog> createState() => _InsertPhotoDialogState();
}

class _InsertPhotoDialogState extends State<InsertPhotoDialog> {
  String? selectedGroup;
  int selectedPosition = 0;
  String? selectedImagePath;
  bool isFromAssets = true; // true=从assets选择，false=从设备相册选择
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.availableGroups.isNotEmpty) {
      selectedGroup = widget.availableGroups.first;
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
    
    Get.dialog(
      Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择图片',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: availableImages.length,
                  itemBuilder: (context, index) {
                    final imagePath = availableImages[index];
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
                            color: selectedImagePath == imagePath
                                ? Colors.blue
                                : Colors.grey,
                            width: selectedImagePath == imagePath ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('取消'),
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

    return AlertDialog(
      title: const Text('插入图片'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 选择组
            const Text('选择分组:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedGroup,
              isExpanded: true,
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
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // 选择位置
            const Text('选择位置:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
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
                      });
                    },
                  ),
                ),
                Text(
                  selectedPosition == groupPhotoCount 
                      ? '末尾' 
                      : '${selectedPosition + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              '将插入到第 ${selectedPosition + 1} 位（共 $groupPhotoCount 张）',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            
            const SizedBox(height: 16),
            
            // 选择图片来源
            const Text('选择图片:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromAssets,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('从Assets选择'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo),
                    label: const Text('从相册选择'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 显示选中的图片预览
            if (selectedImagePath != null)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: isFromAssets
                      ? Image.asset(selectedImagePath!, fit: BoxFit.cover)
                      : Image.file(File(selectedImagePath!), fit: BoxFit.cover),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('取消'),
        ),
        ElevatedButton(
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
                  Get.snackbar(
                    '成功',
                    '已将图片插入到 "$selectedGroup!" 的第 ${selectedPosition + 1} 位',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
          child: const Text('插入'),
        ),
      ],
    );
  }
}
