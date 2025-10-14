import 'dart:convert';
import 'package:http/http.dart' as http;

/// 图片 API 服务类
/// 提供从 API 获取随机图片的功能
class ImageApiService {
  // API 配置
  static const String _baseUrl = 'https://cn.apihz.cn/api/img/apihzimgbz.php';
  static const String _userId = '88888888'; // 使用公共ID，建议替换为自己的ID
  static const String _userKey = '88888888'; // 使用公共KEY，建议替换为自己的KEY

  /// 图片类型枚举
  static const int IMAGE_TYPE_RANDOM = 0; // 随机分类
  static const int IMAGE_TYPE_GENERAL = 1; // 综合大类
  static const int IMAGE_TYPE_BEAUTY = 2; // 美女

  /// 返回格式枚举
  static const int RETURN_TYPE_JSON = 1; // JSON格式
  static const int RETURN_TYPE_TXT = 2; // TXT格式（直接返回URL）

  /// 获取随机图片URL
  ///
  /// [imageType] 图片类型：0=随机分类，1=综合大类，2=美女
  /// [returnType] 返回格式：1=JSON，2=TXT
  ///
  /// 返回图片URL，如果失败返回null
  static Future<String?> getRandomImage({
    int imageType = IMAGE_TYPE_GENERAL,
    int returnType = RETURN_TYPE_JSON,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'id': _userId,
          'key': _userKey,
          'type': returnType.toString(),
          'imgtype': imageType.toString(),
        },
      );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('请求超时');
            },
          );

      if (response.statusCode == 200) {
        if (returnType == RETURN_TYPE_JSON) {
          // JSON格式响应
          final jsonData = json.decode(response.body);
          if (jsonData['code'] == 200) {
            return jsonData['msg'] as String?;
          } else {
            print('❌ API返回错误: ${jsonData['msg']}');
            return null;
          }
        } else {
          // TXT格式，直接返回URL
          final urlText = response.body.trim();
          // 检查是否是JSON错误响应（频率限制等）
          if (urlText.startsWith('{')) {
            try {
              final jsonData = json.decode(urlText);
              print('❌ API返回错误: ${jsonData['msg']}');
              return null;
            } catch (e) {
              // 不是JSON，返回原文本
              return urlText;
            }
          }
          return urlText;
        }
      } else {
        print('HTTP错误: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('获取图片失败: $e');
      return null;
    }
  }

  /// 批量获取随机图片URL
  ///
  /// [count] 需要获取的图片数量
  /// [imageType] 图片类型
  /// [delayMs] 每次请求间隔（毫秒），避免频率限制，建议至少10000ms
  ///
  /// 返回图片URL列表
  static Future<List<String>> getBatchImages({
    required int count,
    int imageType = IMAGE_TYPE_GENERAL,
    int delayMs = 10000, // 默认10秒间隔
  }) async {
    final List<String> imageUrls = [];

    for (int i = 0; i < count; i++) {
      final url = await getRandomImage(imageType: imageType);
      if (url != null && url.isNotEmpty) {
        imageUrls.add(url);
      }

      // 添加延迟，避免频率限制
      if (i < count - 1) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    return imageUrls;
  }

  /// 使用TXT格式快速获取图片URL（无状态码）
  static Future<String?> getRandomImageFast({
    int imageType = IMAGE_TYPE_GENERAL,
  }) async {
    return getRandomImage(imageType: imageType, returnType: RETURN_TYPE_TXT);
  }

  /// 批量快速获取图片URL
  static Future<List<String>> getBatchImagesFast({
    required int count,
    int imageType = IMAGE_TYPE_GENERAL,
    int delayMs = 10000, // 默认10秒间隔
  }) async {
    final List<String> imageUrls = [];

    for (int i = 0; i < count; i++) {
      final url = await getRandomImageFast(imageType: imageType);
      if (url != null && url.isNotEmpty) {
        imageUrls.add(url);
      }

      // 添加延迟，避免频率限制
      if (i < count - 1) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    return imageUrls;
  }
}
