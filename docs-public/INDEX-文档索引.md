# 📚 文档索引 (Documentation Index)

欢迎来到 Album 项目文档！本文档提供了项目所有公开文档的索引。

## 📖 主要文档

### 项目概览
- [README - 文档说明](./README-文档说明.md) - 文档系统的整体介绍
- [PROJECT_STRUCTURE - 项目结构](./PROJECT_STRUCTURE-项目结构.md) - 项目代码结构和组织方式
- [DEVELOPMENT - 开发指南](./DEVELOPMENT-开发指南.md) - 开发环境设置和开发流程

### 配置与设置
- [PERMISSIONS_SETUP - 权限设置](./PERMISSIONS_SETUP-权限设置.md) - Android/iOS 权限配置指南

## ✨ 功能文档 (features/)

本目录包含已完成功能的详细文档：

### 核心功能
- [FEATURE_HERO_ANIMATION_COMPLETE - Hero动画完成](./features/FEATURE_HERO_ANIMATION_COMPLETE-Hero动画完成.md)
  - 照片浏览页面的过渡动画实现

- [FEATURE_TAG_EDITING_COMPLETE - 标签编辑完成](./features/FEATURE_TAG_EDITING_COMPLETE-标签编辑完成.md)
  - 照片标签的添加、编辑和删除功能

- [FEATURE_PHOTO_LONG_PRESS_OPTIONS - 照片长按选项功能](./features/FEATURE_PHOTO_LONG_PRESS_OPTIONS-照片长按选项功能.md)
  - 长按照片显示操作菜单

- [FEATURE_INSERT_PHOTO - 插入照片功能](./features/FEATURE_INSERT_PHOTO-插入照片功能.md)
  - 在特定位置插入照片的功能

- [FEATURE_DRAGGABLE_INSERT_PLACEHOLDER - 拖拽插入占位符功能](./features/FEATURE_DRAGGABLE_INSERT_PLACEHOLDER-拖拽插入占位符功能.md)
  - 拖拽照片到指定位置的交互实现

- [FEATURE_SIMPLIFIED_TOOLBAR - 简化工具栏功能](./features/FEATURE_SIMPLIFIED_TOOLBAR-简化工具栏功能.md)
  - 精简后的工具栏设计

## 📋 待办事项

- [TODO - 待办事项](./TODO-待办事项.md) - 项目待完成功能和改进计划
  - **欢迎贡献者添加新的功能建议和待办事项！**

## 🔧 技术栈

- **Framework**: Flutter
- **语言**: Dart
- **平台**: Android, iOS
- **数据库**: SQLite (sqflite)
- **状态管理**: StatefulWidget
- **图片选择**: image_picker

## 📝 文档说明

### 公开文档 (docs-public/)
本目录包含所有需要上传到 GitHub 的公开文档，包括：
- 项目说明和开发指南
- 功能特性文档
- API 文档和使用说明
- 待办事项和功能规划

### 私有文档 (docs-private/)
私有文档包含开发过程记录，不上传到 GitHub：
- Bug 修复记录 (bugfixes/)
- 性能优化记录 (improvements/)
- 已归档的历史文档 (archived/)

这些文档仅供本地开发参考，已在 `.gitignore` 中排除。

## 🤝 贡献指南

### 如何添加新功能文档

1. 在 `features/` 目录下创建新的 Markdown 文件
2. 文件命名格式: `FEATURE_<NAME>-<中文名称>.md`
3. 包含以下章节：
   - 功能概述
   - 实现细节
   - 使用方法
   - 相关文件
   - 注意事项

### 如何添加待办事项

请直接编辑 [TODO-待办事项.md](./TODO-待办事项.md) 文件，按照优先级添加新的待办项。

## 📞 联系方式

如有问题或建议，欢迎通过 GitHub Issues 反馈。

---

*最后更新: 2025-10-21*
*项目维护: Cksheuen*
