# 📸 Flutter 相册应用

> 基于 Flutter + GetX 的现代化响应式相册应用

## ✨ 特性

- 🎨 **GetX 响应式架构** - 全面使用 Rx 响应式编程
- 📱 **本地/网络双模式** - 支持本地图片和 API 动态加载
- 🎯 **自定义滚动条** - 带分组指示器的虚拟化滚动
- 🔄 **Hero 动画** - 流畅的图片过渡效果
- 🎯 **智能分组** - 按年/月/日自动分组
- ⚡ **性能优化** - 虚拟化渲染 + 图片缓存
- 🛠️ **自动化脚本** - 一键扫描 assets 目录
- ➕ **图片插入** - 向任意组内任意位置插入图片

## 🚀 快速开始

### 1. 安装依赖

```bash
# 克隆项目
git clone <your-repo-url>
cd album

# 安装依赖
flutter pub get
```

### 2. 添加本地图片（推荐方式）

本应用默认使用本地 assets 图片模式，无需网络连接即可运行。

#### 步骤 1: 准备图片

将您的图片文件（支持 `.jpg`, `.jpeg`, `.png` 等格式）放入 `assets/imgs/` 目录：

```bash
# 示例目录结构
assets/imgs/
├── photo1.jpg
├── photo2.png
├── photo3.jpg
└── ...
```

#### 步骤 2: 运行自动扫描脚本

使用提供的 Shell 脚本自动生成图片列表：

```bash
# 1. 添加执行权限（首次使用）
chmod +x generate_assets.sh

# 2. 运行脚本
./generate_assets.sh
```

**脚本功能**:
- 自动扫描 `assets/imgs/` 目录下的所有图片
- 生成 `lib/common/utils/assets_image_manager.dart` 文件
- 创建图片路径列表，供应用读取

**执行结果示例**:
```bash
✅ 成功生成 lib/common/utils/assets_image_manager.dart
📊 找到 20 个文件
```

#### 步骤 3: 更新 pubspec.yaml（如果需要）

确保 `pubspec.yaml` 中已配置 assets 目录：

```yaml
flutter:
  assets:
    - assets/imgs/
```

#### 步骤 4: 运行应用

```bash
# 首次运行或完全重启
flutter run

# 热重载（如果应用已运行）
按 r 键
```

### 3. 验证本地图片加载

启动应用后，您将看到：
- ✅ 封面图片正确显示
- ✅ 相册列表展示所有本地图片
- ✅ 按年/月/日自动分组
- ✅ 滚动条带分组指示器
- ✅ 无需网络连接

### 4. 添加/修改图片

如果需要添加、删除或修改图片：

```bash
# 1. 修改 assets/imgs/ 目录中的图片
#    - 添加新图片
#    - 删除旧图片
#    - 替换现有图片

# 2. 重新运行脚本
./generate_assets.sh

# 3. 重新加载应用
#    - 热重载: 按 r 键
#    - 或完全重启: flutter run
```

## 📖 使用指南

### 本地图片模式（默认）

**优势**:
- ⚡ 瞬间加载，无延迟
- 🔒 无需网络连接
- 💾 节省流量
- 🎯 适合固定图片集合

**适用场景**:
- 个人相册展示
- Demo 演示
- 离线应用

### API 网络模式（可选）

如需切换到 API 模式，在应用中调用：

```dart
// 切换到 API 模式
await controller.switchToApiMode();

// 切换回本地模式
controller.switchToLocalMode();
```

**优势**:
- 🌐 动态内容加载
- 📈 支持分页加载
- 🔄 自动更新数据

## 🏗️ 技术栈

- **Flutter** 3.9.2
- **Dart SDK** ^3.9.2
- **GetX** 4.7.2 - 状态管理 + 路由
- **HTTP** 1.2.0 - 网络请求
- **CachedNetworkImage** 3.3.1 - 图片缓存

## 📂 项目结构

```
lib/
├── common/              # 公共组件
│   ├── routers/         # GetX 路由配置
│   ├── utils/           # 工具类
│   │   └── assets_image_manager.dart  # 自动生成的图片管理类
│   └── widgets/         # 通用组件
│       ├── custom_scrollbar.dart      # 自定义滚动条
│       └── photo_image.dart           # 图片组件
├── models/              # 数据模型
│   └── photo_model.dart               # 照片模型
├── mock/                # Mock 数据
│   └── photo_mock_data.dart           # 本地数据生成
├── pages/               # 页面
│   └── splash/          # 相册页 (MVC 架构)
│       ├── binding.dart               # GetX 绑定
│       ├── controller.dart            # 控制器
│       └── view.dart                  # 视图
├── services/            # 服务层
│   └── api_photo_loader.dart          # API 加载服务
└── main.dart            # 应用入口

assets/
└── imgs/                # 本地图片目录
    └── *.jpg            # 您的图片文件
```

## 🎯 核心特性

### 1. GetX 响应式架构

```dart
// Controller - 定义响应式变量
final RxList<PhotoModel> photos = <PhotoModel>[].obs;

// View - 自动更新 UI
Obx(() => Text('共 ${controller.photos.length} 张'))
```

### 2. 自定义滚动条

- 🖱️ 拖拽快速滚动
- 📍 分组指示器提示
- 🎨 完全响应式设计
- ✨ 动画效果流畅

### 3. 虚拟化渲染

只渲染可视区域 + 上下缓冲区，优化大列表性能：
- ⚡ 支持数千张图片流畅滚动
- 💾 内存占用低
- 🔄 按需加载

### 4. 智能分组

```dart
// 按年分组
controller.changeGroupType(GroupType.year);

// 按月分组（默认）
controller.changeGroupType(GroupType.month);

// 按日分组
controller.changeGroupType(GroupType.day);
```

### 5. 自动化脚本

`generate_assets.sh` 脚本功能：
- 📂 自动扫描 `assets/imgs/` 目录
- 📝 生成 Dart 代码文件
- 🔄 更新图片列表
- ✅ 零手动配置

### 6. 图片插入功能 ⭐ 新增

强大的图片插入功能，支持：
- 📍 向任意分组的任意位置插入图片
- 📷 从设备相册选择图片
- 🖼️ 从 Assets 中选择图片
- 🎯 精确控制插入位置
- 👀 实时预览选中图片

**使用方法**：
1. 点击右下角的「插入图片」浮动按钮
2. 选择目标分组和位置
3. 选择图片来源（Assets 或相册）
4. 预览并确认插入

详细说明请查看 **[FEATURE_INSERT_PHOTO.md](./FEATURE_INSERT_PHOTO.md)**

## 🔧 配置选项

### 修改分组方式

在应用中切换分组：

```dart
// 按年
controller.changeGroupType(GroupType.year);

// 按月
controller.changeGroupType(GroupType.month);

// 按日
controller.changeGroupType(GroupType.day);
```

### 修改排序方式

```dart
// 降序（新→旧，默认）
controller.changeSortType(SortType.dateDesc);

// 升序（旧→新）
controller.changeSortType(SortType.dateAsc);
```

### 标签筛选

```dart
// 按标签筛选
controller.filterByTag('风景');

// 清除筛选
controller.clearFilter();
```

## 📝 开发

### 运行测试

```bash
flutter test
```

### 代码格式化

```bash
dart format .
```

### 代码分析

```bash
flutter analyze
```

### 构建发布版本

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

## 📚 文档

详细文档请查看：

- 📖 **[DEVELOPMENT.md](./DEVELOPMENT.md)** - 完整开发文档
  - 技术栈详解
  - 三种加载模式
  - GetX 最佳实践
  - API 集成指南
  - 性能优化技巧

- 📖 **[FEATURE_INSERT_PHOTO.md](./FEATURE_INSERT_PHOTO.md)** - 图片插入功能说明 ⭐ 新增
  - 功能特性详解
  - 使用流程说明
  - 技术实现细节
  - 权限配置指南

- 📖 **[PERMISSIONS_SETUP.md](./PERMISSIONS_SETUP.md)** - 权限配置指南
  - iOS 权限配置
  - Android 权限配置
  - 常见问题解答

- 📖 **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)** - 项目结构说明
  - 文件组织架构
  - 依赖关系图
  - 核心模块介绍

- 📖 **[OPTIMIZATION_SUMMARY.md](./OPTIMIZATION_SUMMARY.md)** - 优化总结
  - 优化前后对比
  - 性能提升数据
  - 最佳实践建议

## 🐛 已知问题修复

本项目已修复以下问题：

- ✅ **Assets 加载"加载更多"提示** - [ASSETS_LOADING_FIX.md](./ASSETS_LOADING_FIX.md)
- ✅ **滚动条拖拽对齐问题** - [SCROLLBAR_BUG_FIX_FINAL.md](./SCROLLBAR_BUG_FIX_FINAL.md)
- ✅ **分组切换滚动条更新** - [SCROLLBAR_GROUP_UPDATE_FIX.md](./SCROLLBAR_GROUP_UPDATE_FIX.md)

## ❓ 常见问题

### Q: 如何添加更多图片？

A: 将图片放入 `assets/imgs/` 目录，然后运行 `./generate_assets.sh`，最后重启应用。

### Q: 为什么图片不显示？

A: 
1. 确认图片在 `assets/imgs/` 目录
2. 确认已运行 `./generate_assets.sh`
3. 确认 `pubspec.yaml` 中配置了 `assets/imgs/`
4. 完全重启应用（非热重载）

### Q: 如何切换到 API 模式？

A: 在 `lib/pages/splash/controller.dart` 中调用 `switchToApiMode()`。

### Q: 支持哪些图片格式？

A: 支持 Flutter 标准的图片格式：`.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`, `.bmp`。

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 贡献指南

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

**更多详情**: 查看 [DEVELOPMENT.md](./DEVELOPMENT.md) 获取完整开发文档
