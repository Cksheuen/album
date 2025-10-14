#!/bin/bash

# 自动生成 assets 图片列表的脚本
# 使用方法: chmod +x generate_assets.sh && ./generate_assets.sh

ASSETS_DIR="assets/imgs"
OUTPUT_FILE="lib/common/utils/assets_image_manager.dart"

echo "/// Assets 图片管理类" > $OUTPUT_FILE
echo "/// 自动生成 - 请勿手动编辑" >> $OUTPUT_FILE
echo "/// 运行 ./generate_assets.sh 重新生成" >> $OUTPUT_FILE
echo "class AssetsImageManager {" >> $OUTPUT_FILE
echo "  // 图片文件列表 - 自动生成" >> $OUTPUT_FILE
echo "  static const List<String> _imageFiles = [" >> $OUTPUT_FILE

# 遍历 assets/imgs 目录
for file in $ASSETS_DIR/*; do
  if [[ -f "$file" ]]; then
    filename=$(basename "$file")
    echo "    '$filename'," >> $OUTPUT_FILE
  fi
done

echo "  ];" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "  /// 获取所有图片的完整路径" >> $OUTPUT_FILE
echo "  static List<String> getAllImagePaths() {" >> $OUTPUT_FILE
echo "    return _imageFiles.map((file) => 'assets/imgs/\$file').toList();" >> $OUTPUT_FILE
echo "  }" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "  /// 获取图片数量" >> $OUTPUT_FILE
echo "  static int get imageCount => _imageFiles.length;" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "  /// 获取指定索引的图片路径" >> $OUTPUT_FILE
echo "  static String getImagePath(int index) {" >> $OUTPUT_FILE
echo "    if (index < 0 || index >= _imageFiles.length) {" >> $OUTPUT_FILE
echo "      throw RangeError('Index out of range: \$index');" >> $OUTPUT_FILE
echo "    }" >> $OUTPUT_FILE
echo "    return 'assets/imgs/\${_imageFiles[index]}';" >> $OUTPUT_FILE
echo "  }" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "  /// 检查图片是否存在（通过文件名）" >> $OUTPUT_FILE
echo "  static bool hasImage(String fileName) {" >> $OUTPUT_FILE
echo "    return _imageFiles.contains(fileName);" >> $OUTPUT_FILE
echo "  }" >> $OUTPUT_FILE
echo "}" >> $OUTPUT_FILE

echo "✅ 成功生成 $OUTPUT_FILE"
echo "📊 找到 $(ls -1 $ASSETS_DIR | wc -l | xargs) 个文件"
