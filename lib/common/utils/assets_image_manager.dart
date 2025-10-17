/// Assets 图片管理类
/// 自动生成 - 请勿手动编辑
/// 运行 ./generate_assets.sh 重新生成
class AssetsImageManager {
  // 图片文件列表 - 自动生成
  static const List<String> _imageFiles = [
    '126351103_p0_master1200.jpg',
    '126351103_p1_master1200.jpg',
    '126351103_p2_master1200.jpg',
    '126351103_p3_master1200.jpg',
    '126351103_p4_master1200.jpg',
    '126351103_p5_master1200.jpg',
    '126351103_p6_master1200.jpg',
    '126351103_p7_master1200.jpg',
    '126351103_p8_master1200.jpg',
    '126351103_p9_master1200.jpg',
    '128181590_p0_master1200.jpg',
    '128181590_p1_master1200.jpg',
    '128181590_p2_master1200.jpg',
    '128181590_p3_master1200.jpg',
    '128181590_p4_master1200.jpg',
    '128181590_p5_master1200.jpg',
    '128181590_p6_master1200.jpg',
  ];

  /// 获取所有图片的完整路径
  static List<String> getAllImagePaths() {
    return _imageFiles.map((file) => 'assets/imgs/$file').toList();
  }

  /// 获取图片数量
  static int get imageCount => _imageFiles.length;

  /// 获取指定索引的图片路径
  static String getImagePath(int index) {
    if (index < 0 || index >= _imageFiles.length) {
      throw RangeError('Index out of range: $index');
    }
    return 'assets/imgs/${_imageFiles[index]}';
  }

  /// 检查图片是否存在（通过文件名）
  static bool hasImage(String fileName) {
    return _imageFiles.contains(fileName);
  }
}
