import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 照片长按选项底部弹窗
/// 提供删除、分享、编辑等操作
class PhotoOptionsSheet extends StatelessWidget {
  final String photoPath;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onViewDetails;
  final VoidCallback? onSetAsWallpaper;

  const PhotoOptionsSheet({
    Key? key,
    required this.photoPath,
    this.onDelete,
    this.onShare,
    this.onEdit,
    this.onViewDetails,
    this.onSetAsWallpaper,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部拖动条
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.photo, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '照片操作',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // 选项列表
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                if (onShare != null)
                  _buildOptionTile(
                    icon: Icons.share,
                    iconColor: Colors.blue,
                    title: '分享',
                    subtitle: '分享到其他应用',
                    onTap: () {
                      Get.back();
                      onShare?.call();
                    },
                  ),
                
                if (onEdit != null)
                  _buildOptionTile(
                    icon: Icons.edit,
                    iconColor: Colors.orange,
                    title: '编辑',
                    subtitle: '裁剪、滤镜、调整',
                    onTap: () {
                      Get.back();
                      onEdit?.call();
                    },
                  ),
                
                if (onViewDetails != null)
                  _buildOptionTile(
                    icon: Icons.info_outline,
                    iconColor: Colors.green,
                    title: '查看详情',
                    subtitle: '查看照片信息',
                    onTap: () {
                      Get.back();
                      onViewDetails?.call();
                    },
                  ),
                
                if (onSetAsWallpaper != null)
                  _buildOptionTile(
                    icon: Icons.wallpaper,
                    iconColor: Colors.purple,
                    title: '设为壁纸',
                    subtitle: '设置为设备壁纸',
                    onTap: () {
                      Get.back();
                      onSetAsWallpaper?.call();
                    },
                  ),
                
                if (onDelete != null)
                  _buildOptionTile(
                    icon: Icons.delete_outline,
                    iconColor: Colors.red,
                    title: '删除',
                    subtitle: '从相册中删除此照片',
                    onTap: () {
                      Get.back();
                      _showDeleteConfirmation(context);
                    },
                    isDestructive: true,
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 构建选项条目
  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('确认删除'),
          ],
        ),
        content: const Text('确定要删除这张照片吗？\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// 静态方法：显示照片选项底部弹窗
  static void show({
    required String photoPath,
    VoidCallback? onDelete,
    VoidCallback? onShare,
    VoidCallback? onEdit,
    VoidCallback? onViewDetails,
    VoidCallback? onSetAsWallpaper,
  }) {
    Get.bottomSheet(
      PhotoOptionsSheet(
        photoPath: photoPath,
        onDelete: onDelete,
        onShare: onShare,
        onEdit: onEdit,
        onViewDetails: onViewDetails,
        onSetAsWallpaper: onSetAsWallpaper,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    );
  }
}
