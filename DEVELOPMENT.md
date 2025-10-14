# 相册应用开发文档

> Flutter + GetX 响应式相册应用完整开发指南

## 📚 目录

- [项目概述](#项目概述)
- [快速开始](#快速开始)
- [核心功能](#核心功能)
- [API 集成](#api-集成)
- [本地资源管理](#本地资源管理)
- [架构设计](#架构设计)
- [开发指南](#开发指南)

---

## 项目概述

这是一个基于 Flutter 和 GetX 的响应式相册应用，支持本地图片展示和网络 API 动态加载。

### 技术栈

- **Flutter**: 3.9.2
- **Dart SDK**: ^3.9.2
- **GetX**: 4.7.2 (状态管理 + 路由)
- **HTTP**: 1.2.0 (网络请求)
- **CachedNetworkImage**: 3.3.1 (图片缓存)

### 核心特性

✅ **本地图片管理** - 自动扫描 assets 目录  
✅ **API 动态加载** - 支持网络图片渐进加载  
✅ **GetX 响应式** - 全面使用 Rx 响应式编程  
✅ **自定义滚动条** - 带指示器的虚拟化滚动  
✅ **分组展示** - 按年/月/日分组  
✅ **Hero 动画** - 流畅的图片过渡效果  

---

## 快速开始

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 运行应用

```bash
flutter run
```

### 3. 三种图片加载模式

#### 模式 1: 本地图片（默认）✅

**特点**: 快速加载，无需网络

```dart
// 当前默认配置，lib/pages/splash/controller.dart
final photos = PhotoMockData.generateMockPhotos();
```

#### 模式 2: API 动态加载

**修改 controller.dart 的 `_initializePhotos()` 方法：**

```dart
// 使用 API 加载
final photos = await apiLoader.loadPhotos(1);
apiLoader.startAutoLoading(
  targetCount: 10,
  currentCount: photos.length,
  onPhotoLoaded: (newPhotos) {
    _allPhotos.addAll(newPhotos);
    _updateGroupedPhotos();
  },
);
```

#### 模式 3: 动态切换

```dart
// 切换到 API 模式
await controller.switchToApiMode();

// 切换到本地模式
controller.switchToLocalMode();

// 加载更多 API 图片
await controller.loadMorePhotos();
```

---

## 核心功能

### 1. 响应式状态管理（GetX Rx）

所有状态使用 GetX 响应式变量：

```dart
// Controller
final RxList<PhotoModel> _allPhotos = <PhotoModel>[].obs;
final RxBool _isLoading = true.obs;
final RxString _selectedTag = ''.obs;

// View - 自动响应更新
Obx(() => Text('共 ${controller.allPhotos.length} 张'));
```

### 2. 自定义滚动条

**特性**:
- ✅ 拖拽滚动
- ✅ 分组指示器
- ✅ 虚拟化渲染
- ✅ 响应式状态

**实现**:
```dart
// 使用 GetX Rx 变量管理状态
final RxBool _isDragging = false.obs;
final RxString _currentGroupTitle = ''.obs;
final RxDouble _scrollPosition = 0.0.obs;
```

### 3. 分组展示

支持三种分组方式：

- **按年分组**: `GroupType.year`
- **按月分组**: `GroupType.month` (默认)
- **按日分组**: `GroupType.day`

```dart
controller.changeGroupType(GroupType.month);
```

### 4. 虚拟化网格

只渲染可视区域的图片，优化性能：

```dart
class _VirtualizedGroupedGrid extends StatefulWidget {
  // 自动计算视口范围
  // 只渲染可见 + 缓冲区的图片
  // 使用 AnimatedPositioned 实现流畅过渡
}
```

---

## API 集成

### API 配置

**接口**: `https://cn.apihz.cn/api/img/apihzimgbz.php`

**参数**:
- `id`: 会员ID
- `key`: 密钥
- `type`: 1=JSON, 2=TXT
- `imgtype`: 0=随机, 1=综合, 2=美女

**频率限制**: 建议 ≥10 秒间隔

### API 加载器

封装在 `lib/services/api_photo_loader.dart`：

```dart
class ApiPhotoLoader {
  // 加载图片
  Future<List<PhotoModel>> loadPhotos(int count);
  
  // 自动加载
  Future<void> startAutoLoading({...});
  
  // 停止加载
  void stopAutoLoading();
  
  // 加载更多（分页）
  Future<List<PhotoModel>> loadMore();
  
  // 重置
  void reset();
  
  // 统计信息
  Map<String, dynamic> getStats();
}
```

### 使用示例

```dart
// 创建加载器
final apiLoader = ApiPhotoLoader(
  pageSize: 10,
  autoLoadIntervalSeconds: 10,
);

// 加载 1 张图片
final photos = await apiLoader.loadPhotos(1);

// 启动自动加载
apiLoader.startAutoLoading(
  targetCount: 10,
  currentCount: photos.length,
  onPhotoLoaded: (newPhotos) {
    _allPhotos.addAll(newPhotos);
  },
);
```

---

## 本地资源管理

### 自动扫描脚本

`generate_assets.sh` 自动扫描 `assets/imgs` 目录并生成代码：

```bash
#!/bin/bash

# 运行脚本
./generate_assets.sh
```

**输出**: `lib/common/utils/assets_image_manager.dart`

### AssetsImageManager

自动生成的资源管理类：

```dart
class AssetsImageManager {
  static const List<String> _imageFiles = [
    '126351103_p0_master1200.jpg',
    '126351103_p1_master1200.jpg',
    // ... 自动生成
  ];
  
  static List<String> getAllImagePaths();
  static int get imageCount;
  static String getImagePath(int index);
  static bool hasImage(String fileName);
}
```

### 使用方式

```dart
// 在 PhotoMockData 中使用
final imagePaths = AssetsImageManager.getAllImagePaths();

// 添加新图片后重新运行脚本
./generate_assets.sh
```

---

## 架构设计

### 项目结构

```
lib/
├── common/                    # 公共组件
│   ├── index.dart            # 统一导出
│   ├── routers/              # 路由配置
│   │   ├── names.dart        # 路由名称
│   │   └── pages.dart        # 路由页面
│   ├── utils/                # 工具类
│   │   └── assets_image_manager.dart  # 资源管理
│   └── widgets/              # 通用组件
│       ├── custom_scrollbar.dart      # 自定义滚动条
│       └── photo_image.dart           # 图片组件
├── models/                   # 数据模型
│   └── photo_model.dart
├── mock/                     # Mock 数据
│   └── photo_mock_data.dart
├── pages/                    # 页面
│   ├── index.dart
│   └── splash/               # 相册页面
│       ├── binding.dart      # GetX 依赖注入
│       ├── controller.dart   # 控制器
│       ├── index.dart        # 导出
│       └── view.dart         # 视图
├── services/                 # 服务层
│   ├── api_photo_loader.dart # API 加载器
│   └── image_api_service.dart # API 服务
└── main.dart                 # 入口
```

### GetX 架构模式

**1. Binding (依赖注入)**

```dart
class SplashBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SplashController());
  }
}
```

**2. Controller (业务逻辑)**

```dart
class SplashController extends GetxController {
  final RxList<PhotoModel> _allPhotos = <PhotoModel>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializePhotos();
  }
}
```

**3. View (UI 界面)**

```dart
class SplashPage extends GetView<SplashController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => /* 响应式 UI */);
  }
}
```

### 响应式设计原则

✅ **使用 Rx 变量替代 setState**

```dart
// ❌ 不推荐
setState(() { count++; });

// ✅ 推荐
final RxInt count = 0.obs;
count.value++;
```

✅ **使用 Obx 自动监听**

```dart
Obx(() => Text('${controller.count}'))
```

✅ **使用 GetX Worker**

```dart
@override
void onInit() {
  super.onInit();
  ever(_allPhotos, (_) => print('照片列表变化'));
  debounce(_searchText, (_) => search(), time: Duration(seconds: 1));
}
```

---

## 开发指南

### 1. 添加新图片

```bash
# 1. 将图片放入 assets/imgs/
# 2. 运行脚本
./generate_assets.sh
# 3. 重启应用
```

### 2. 切换加载模式

**方法 1: 修改初始化代码**

编辑 `lib/pages/splash/controller.dart` 的 `_initializePhotos()`

**方法 2: 添加切换按钮**

```dart
ElevatedButton(
  onPressed: () async {
    await controller.switchToApiMode();
  },
  child: Text('切换到 API 模式'),
)
```

### 3. 自定义分组

在 `PhotoMockData` 中添加新的分组方法：

```dart
static Map<String, List<PhotoModel>> groupPhotosByCustom(
  List<PhotoModel> photos,
) {
  // 自定义分组逻辑
}
```

### 4. 添加过滤标签

```dart
// 按标签过滤
controller.filterByTag('风景');

// 清除过滤
controller.clearFilter();
```

### 5. 修改 API 参数

编辑 `lib/services/api_photo_loader.dart`:

```dart
final imageUrls = await ImageApiService.getBatchImagesFast(
  count: count,
  imageType: ImageApiService.IMAGE_TYPE_BEAUTY, // 修改类型
  delayMs: 5000, // 修改间隔
);
```

### 6. 性能优化

**虚拟化渲染**:
- 只渲染可视区域 + 缓冲区（200px）
- 使用 `AnimatedPositioned` 流畅过渡
- 稳定的 key 值避免重建

**图片缓存**:
- 网络图片使用 `CachedNetworkImage`
- 自动缓存到本地
- 支持离线访问

**GetX 优化**:
- 使用 `Get.lazyPut` 懒加载
- 使用 `Get.find` 复用实例
- 避免不必要的 `rebuild`

---

## 常见问题

### Q1: 如何禁用 API 加载？

**A**: 默认已禁用，使用本地图片。如需启用，参考"快速开始 - 模式 2"。

### Q2: 如何修改滚动条样式？

**A**: 编辑 `lib/common/widgets/custom_scrollbar.dart`，调整以下参数：

```dart
static const double scrollbarWidth = 40.0;
static const double thumbMinHeight = 48.0;
static const Color scrollbarColor = Color(0xFF2196F3);
```

### Q3: 如何添加新的排序方式？

**A**: 在 `SortType` 枚举中添加新类型，然后在 `_updateGroupedPhotos()` 中实现逻辑。

### Q4: API 调用频率限制怎么办？

**A**: 已设置 10 秒间隔，如需调整：

```dart
final ApiPhotoLoader apiLoader = ApiPhotoLoader(
  autoLoadIntervalSeconds: 15, // 改为 15 秒
);
```

---

## 更新日志

### v1.0.0 (2025-10-14)

- ✅ 初始版本
- ✅ 本地图片支持
- ✅ API 集成
- ✅ GetX 响应式重构
- ✅ 虚拟化滚动优化
- ✅ 自定义滚动条
- ✅ 分组展示
- ✅ 自动资源管理

---

## 贡献指南

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 许可证

本项目采用 MIT 许可证。

---

## 联系方式

- 项目主页: [GitHub Repository]
- 问题反馈: [Issues]
- 文档: [Documentation]
