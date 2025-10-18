import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/photo_model.dart';
import '../../common/utils/assets_image_manager.dart';
import 'package:image_picker/image_picker.dart';

/// 简化的插入照片工具栏
/// 只包含：选择图片 + 确认插入 两个按钮
/// 位置调整通过拖动占位符完成，无需复杂的控制面板
class InsertPhotoToolbar extends StatefulWidget {
  final Function(PhotoModel photo) onConfirmInsert;
  final VoidCallback? onCancel;
  final Function(String imagePath, bool isFromAssets)? onImageSelected; // 新增：图片选择回调

  const InsertPhotoToolbar({
    Key? key,
    required this.onConfirmInsert,
    this.onCancel,
    this.onImageSelected,
  }) : super(key: key);

  @override
  State<InsertPhotoToolbar> createState() => _InsertPhotoToolbarState();
}

class _InsertPhotoToolbarState extends State<InsertPhotoToolbar> {
  String? selectedImagePath;
  bool isFromAssets = true;
  
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          selectedImagePath = image.path;
          isFromAssets = false;
        });
        // 通知父组件图片已选中
        widget.onImageSelected?.call(image.path, false);
      }
    } catch (e) {
      Get.snackbar('错误', '选择图片失败: $e', snackPosition: SnackPosition.TOP);
    }
  }

  void _pickFromAssets() {
    final availableImages = AssetsImageManager.getAllImagePaths();
    
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
                    '选择本地图片',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
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
                        // 通知父组件图片已选中
                        widget.onImageSelected?.call(imagePath, true);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey[300]!,
                            width: isSelected ? 3 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                imagePath, 
                                fit: BoxFit.cover,
                                // 添加缓存配置，避免重复加载
                                cacheWidth: 200,
                                cacheHeight: 200,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error, color: Colors.red),
                                  );
                                },
                              ),
                            ),
                            if (isSelected)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
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

  /// 上传图片到服务器（预留接口）
  /// 
  /// 用于将本地选择的图片上传到服务器
  /// 返回上传后的图片 URL
  // Future<String?> _uploadImage(String localPath) async {
  //   try {
  //     // TODO: 实现图片上传逻辑
  //     // 1. 读取本地文件
  //     final file = File(localPath);
  //     
  //     // 2. 调用上传 API
  //     // final response = await http.post(
  //     //   Uri.parse('YOUR_UPLOAD_API_URL'),
  //     //   body: {
  //     //     'file': await MultipartFile.fromFile(file.path),
  //     //   },
  //     // );
  //     //
  //     // 3. 解析响应获取图片 URL
  //     // if (response.statusCode == 200) {
  //     //   final data = json.decode(response.body);
  //     //   return data['url'];
  //     // }
  //     
  //     return null;
  //   } catch (e) {
  //     print('上传图片失败: $e');
  //     return null;
  //   }
  // }

  void _confirmInsert() async {
    if (selectedImagePath == null) {
      Get.snackbar(
        '提示',
        '请先选择要插入的图片',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // 显示加载提示
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在处理图片...'),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      String finalPath = selectedImagePath!;
      
      // 如果是从相册选择的图片，可以选择上传到服务器
      // if (!isFromAssets) {
      //   // 上传图片到服务器
      //   final uploadedUrl = await _uploadImage(selectedImagePath!);
      //   if (uploadedUrl != null) {
      //     finalPath = uploadedUrl;
      //   }
      // }

      final photo = PhotoModel(
        path: finalPath,
        date: DateTime.now(),
        title: '新插入的图片',
        tags: ['inserted'],
        isNetworkImage: false, // 如果上传成功，这里可以改为 true
      );

      // 关闭加载对话框
      Get.back();
      
      // 调用插入回调
      widget.onConfirmInsert(photo);
      
    } catch (e) {
      // 关闭加载对话框
      Get.back();
      
      Get.snackbar(
        '错误',
        '处理图片失败: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 外层容器：延伸到屏幕底部作为背景
      color: Colors.white,
      child: SafeArea(
        // SafeArea 只影响内部内容，不影响背景
        top: false, // 不需要顶部安全区
        child: Container(
          height: 80,
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
          child: Row(
            children: [
              const SizedBox(width: 8),
              
              // 取消按钮（可选）
              if (widget.onCancel != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: widget.onCancel,
                  tooltip: '取消',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            
            const Spacer(),
            
            // 从相册选择按钮（只显示图标）
            IconButton(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              tooltip: '从相册选择',
              color: Colors.blue[700],
              iconSize: 28,
            ),
            
            // 从本地资源选择按钮（只显示图标）
            IconButton(
              onPressed: _pickFromAssets,
              icon: const Icon(Icons.folder),
              tooltip: '从本地选择',
              color: Colors.green[700],
              iconSize: 28,
            ),
            
            const SizedBox(width: 4),
            
            // 确认插入按钮
            ElevatedButton.icon(
              onPressed: _confirmInsert,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('确认', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                elevation: 2,
                minimumSize: const Size(0, 36),
              ),
            ),
            
            const SizedBox(width: 8),
          ],
        ),
        ), // SafeArea 闭合
      ), // 外层 Container 闭合
    );
  }
}
