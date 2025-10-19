class PhotoModel {
  final String path;
  final DateTime date;
  final String? title;
  List<String>? tags; // 改为可变的，支持修改标签
  final bool isNetworkImage; // 标识是否为网络图片

  PhotoModel({
    required this.path,
    required this.date,
    this.title,
    this.tags,
    this.isNetworkImage = false, // 默认为本地图片
  });

  // 便于日期比较的getter
  String get yearMonth => '${date.year}年${date.month}月';
  String get yearMonthDay => '${date.year}年${date.month}月${date.day}日';
  String get year => '${date.year}年';

  // 判断是否为有效的网络URL
  bool get isValidNetworkUrl {
    if (!isNetworkImage) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  // 便于排序
  int compareTo(PhotoModel other) {
    return date.compareTo(other.date);
  }

  @override
  String toString() {
    return 'PhotoModel{path: $path, date: $date, title: $title, isNetwork: $isNetworkImage}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoModel &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          date == other.date;

  @override
  int get hashCode => path.hashCode ^ date.hashCode;
}
