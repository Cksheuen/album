# 📁 项目文件结构

## 核心文件（16 个 Dart 文件）

```
lib/
├── main.dart                                    # 应用入口
│
├── common/                                      # 公共模块
│   ├── index.dart                              # 统一导出
│   ├── routers/                                # 路由配置
│   │   ├── names.dart                          # 路由名称常量
│   │   └── pages.dart                          # 路由页面配置
│   ├── utils/                                  # 工具类
│   │   └── assets_image_manager.dart          # 资源管理器（自动生成）
│   └── widgets/                                # 通用组件
│       ├── custom_scrollbar.dart              # 自定义滚动条（GetX响应式）
│       └── photo_image.dart                   # 图片组件
│
├── models/                                     # 数据模型
│   └── photo_model.dart                       # 照片模型
│
├── mock/                                       # Mock数据
│   └── photo_mock_data.dart                   # 照片数据生成器
│
├── pages/                                      # 页面模块
│   ├── index.dart                             # 页面导出
│   └── splash/                                # 相册页面（GetX MVC）
│       ├── index.dart                         # 模块导出
│       ├── binding.dart                       # 依赖注入
│       ├── controller.dart                    # 业务逻辑
│       └── view.dart                          # UI界面
│
└── services/                                   # 服务层
    ├── api_photo_loader.dart                  # API加载器（封装）
    └── image_api_service.dart                 # API服务
```

## 文档文件（4 个）

```
├── README.md                    (5.9K)  # 项目简介
├── DEVELOPMENT.md              (10K)   # 完整开发文档
├── OPTIMIZATION_SUMMARY.md     (6.2K)  # 优化总结
└── README.old.md               (3.1K)  # 旧README备份
```

## 脚本文件

```
├── generate_assets.sh                  # 自动扫描assets脚本
└── pubspec.yaml                        # 项目配置
```

## 资源文件

```
assets/
└── imgs/                               # 图片资源（17张）
    ├── 126351103_p0_master1200.jpg
    ├── 126351103_p1_master1200.jpg
    └── ... (共17张)
```

## 文件统计

### Dart 文件分布

| 目录 | 文件数 | 说明 |
|------|--------|------|
| common/ | 5 | 公共组件和工具 |
| models/ | 1 | 数据模型 |
| mock/ | 1 | Mock数据 |
| pages/ | 5 | 页面模块 |
| services/ | 2 | 服务层 |
| 根目录 | 2 | 入口和导出 |
| **总计** | **16** | **核心代码** |

### 架构特点

✅ **GetX MVC 模式**
- Binding: 依赖注入
- Controller: 业务逻辑（100% 响应式）
- View: UI界面（Obx 自动更新）

✅ **清晰的分层**
- common: 可复用组件
- models: 数据结构
- services: 业务服务
- pages: 页面模块

✅ **统一导出**
- 每个模块都有 index.dart
- 便于导入和管理

## 代码行数统计

```bash
# 运行以下命令查看
find lib -name "*.dart" -exec wc -l {} + | sort -n
```

预估行数：
- **总代码**: ~2000 行
- **核心逻辑**: ~800 行
- **UI 界面**: ~600 行
- **配置/导出**: ~200 行

## 关键文件说明

### 1. Controller 层
- `lib/pages/splash/controller.dart` - 相册控制器
  - 响应式状态管理
  - 分组、排序、过滤逻辑
  - API/本地模式切换

### 2. View 层  
- `lib/pages/splash/view.dart` - 相册视图
  - 虚拟化网格渲染
  - 自定义滚动条
  - Hero 动画

### 3. Service 层
- `lib/services/api_photo_loader.dart` - API 加载器
  - 自动加载
  - 分页加载
  - 去重处理

### 4. Widget 层
- `lib/common/widgets/custom_scrollbar.dart` - 滚动条
  - GetX Controller 管理状态
  - 拖拽交互
  - 分组指示器

## 依赖关系

```
main.dart
  └─> pages/splash/
        ├─> controller (GetX)
        ├─> view (Obx)
        └─> binding
              └─> services/api_photo_loader
                    └─> services/image_api_service
```