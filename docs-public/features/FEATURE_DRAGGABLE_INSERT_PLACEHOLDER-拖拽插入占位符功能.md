# 功能实现：可拖动插入占位符

## 更新日期
2025-10-18

## 功能概述

实现了插入占位符的拖放功能，用户可以通过长按并拖动占位符来直接调整图片插入位置，提供更直观的交互体验。

## 功能特性

### 1. 可拖动的占位符
- **长按触发**：长按占位符（约0.5秒）激活拖动模式
- **拖动反馈**：拖动时显示半透明的占位符反馈图标
- **原位指示**：拖动时原位置显示淡化的拖动指示器

### 2. 拖放目标识别
- **智能高亮**：当占位符悬停在照片上时，该照片边框变蓝并显示阴影
- **实时更新**：松开占位符时，立即更新插入位置
- **跨组拖动**：支持将占位符拖动到不同的分组中

### 3. 视觉效果

#### 占位符状态
```
静态状态：
- 蓝色边框（3px）
- 脉冲动画背景
- "插入位置" 文字
- "长按拖动" 提示

拖动中（feedback）：
- 半透明蓝色背景（80%）
- 更大的添加图标
- 跟随手指移动

拖动中（原位）：
- 淡化边框（30%）
- 拖动指示器图标
- 半透明背景
```

#### 拖放目标反馈
```
无悬停：
- 白色边框（1px）
- 正常照片显示

悬停时：
- 蓝色边框（3px）
- 蓝色阴影（模糊半径8px，扩展2px）
- 保持照片内容可见
```

## 实现细节

### 1. LongPressDraggable 组件

占位符使用 `LongPressDraggable` 实现拖动功能：

```dart
LongPressDraggable<Map<String, dynamic>>(
  data: {
    'type': 'placeholder',
    'groupKey': widget.insertPlaceholderGroup,
    'position': widget.insertPlaceholderPosition,
  },
  feedback: Material(...), // 拖动时的视觉反馈
  childWhenDragging: Container(...), // 原位的淡化指示器
  child: placeholderWidget, // 正常状态的占位符
)
```

### 2. DragTarget 包裹照片

每个照片项被包裹在 `DragTarget` 中，可以接受占位符的拖放：

```dart
DragTarget<Map<String, dynamic>>(
  onWillAcceptWithDetails: (details) {
    // 只接受 placeholder 类型
    return details.data['type'] == 'placeholder';
  },
  onAcceptWithDetails: (details) {
    // 更新占位符位置
    widget.onPlaceholderDragged?.call(groupKey, position);
  },
  builder: (context, candidateData, rejectedData) {
    // 悬停时显示蓝色边框和阴影
    final bool isHovering = candidateData.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isHovering ? Colors.blue : Colors.white,
          width: isHovering ? 3 : 1,
        ),
        boxShadow: isHovering ? [...] : null,
      ),
      child: photoWidget,
    );
  },
)
```

### 3. 位置更新回调

当占位符被拖放到新位置时，通过回调链更新 controller 中的占位符位置：

```
DragTarget.onAcceptWithDetails 
  → widget.onPlaceholderDragged 
  → controller.showInsertPlaceholder(groupKey, position)
  → 更新 _insertPlaceholderGroup 和 _insertPlaceholderPosition
  → UI 自动响应更新（Obx）
```

## 用户交互流程

### 拖动操作流程
1. 用户长按插入占位符（蓝色方框）
2. 占位符变为可拖动状态，显示半透明反馈图标
3. 用户拖动占位符到目标照片位置
4. 目标照片显示蓝色边框高亮反馈
5. 用户松开手指
6. 占位符立即移动到新位置
7. 控制面板的滑块自动同步更新

### 与控制面板联动
- **拖动 → 面板**：拖动占位符后，控制面板的位置滑块自动更新
- **面板 → 拖动**：通过控制面板调整位置，占位符也会移动到新位置
- **双向同步**：两种方式可以自由切换，实时同步

## 代码变更

### 新增文件
无

### 修改的文件

#### 1. `lib/pages/splash/view.dart`

##### _VirtualizedGroupedGrid Widget
```dart
// 添加拖动回调
final void Function(String groupKey, int position)? onPlaceholderDragged;

const _VirtualizedGroupedGrid({
  // ...其他参数
  this.onPlaceholderDragged,
})
```

##### _buildInsertPlaceholder 方法
```dart
// 将占位符包裹在 LongPressDraggable 中
Widget _buildInsertPlaceholder(double itemSize) {
  final placeholderWidget = Container(...); // 原有UI
  
  return LongPressDraggable<Map<String, dynamic>>(
    data: {...}, // 包含类型、组名、位置信息
    feedback: Material(...), // 拖动反馈UI
    childWhenDragging: Container(...), // 原位指示器
    child: placeholderWidget,
  );
}
```

##### _buildPhotoItem 方法
```dart
// 添加 groupKey 和 position 参数
Widget _buildPhotoItem(
  dynamic photo, 
  String heroTag, 
  double itemSize,
  {String? groupKey, int? position}
) {
  // ...构建 photoWidget
  
  // 包裹 DragTarget
  if (groupKey != null && position != null && !isLoadingPlaceholder) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) => details.data['type'] == 'placeholder',
      onAcceptWithDetails: (details) {
        widget.onPlaceholderDragged?.call(groupKey, position);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;
        // 悬停时显示高亮边框
        return Container(...);
      },
    );
  }
  
  return photoWidget;
}
```

##### 调用处更新
```dart
// 传递拖动回调
_VirtualizedGroupedGrid(
  // ...其他参数
  onPlaceholderDragged: (groupKey, position) {
    controller.showInsertPlaceholder(groupKey, position);
  },
)

// 传递 groupKey 和 position
_buildPhotoItem(
  photo, 
  heroTag, 
  itemSize,
  groupKey: groupTitle,
  position: i,
)
```

## 技术亮点

### 1. 数据驱动
- 拖放操作通过回调更新 controller 状态
- UI 通过 Obx 自动响应状态变化
- 无需手动管理 UI 更新

### 2. 泛型数据传递
```dart
LongPressDraggable<Map<String, dynamic>>(...)
DragTarget<Map<String, dynamic>>(...)
```
使用 Map 传递复杂数据，包括类型标识、组名、位置等

### 3. 条件渲染
- 只有正常照片才被包裹 DragTarget
- 加载占位符不参与拖放交互
- 避免不必要的 widget 包装

### 4. 视觉层次
- 拖动反馈使用 Material 组件确保正确渲染
- 多层 Container 嵌套实现复杂视觉效果
- 动画过渡平滑自然

## 用户体验提升

### Before（添加前）
❌ 只能通过控制面板的滑块调整位置
❌ 需要来回查看相册和控制面板
❌ 不够直观

### After（添加后）
✅ 直接拖动占位符到目标位置
✅ 实时视觉反馈，所见即所得
✅ 支持跨组拖动
✅ 与控制面板双向同步
✅ 更符合直觉的交互方式

## 测试建议

### 功能测试
1. ✅ 长按占位符能否激活拖动
2. ✅ 拖动过程中反馈是否正确显示
3. ✅ 悬停在照片上时高亮是否显示
4. ✅ 松开后占位符是否移动到正确位置
5. ✅ 控制面板滑块是否同步更新

### 边界测试
1. ✅ 拖动到第一张照片位置
2. ✅ 拖动到最后一张照片位置
3. ✅ 跨组拖动（不同日期组）
4. ✅ 拖动到加载占位符附近

### 性能测试
1. ✅ 大量照片时拖动是否流畅
2. ✅ 拖动过程中 UI 是否卡顿
3. ✅ 频繁拖动是否有内存泄漏

## 后续优化空间

### 1. 拖动动画增强
- 占位符可以沿着拖动路径平滑移动到新位置
- 其他照片可以执行"让路"动画

### 2. 拖动范围扩展
- 支持拖动照片交换位置
- 支持拖动照片到其他组

### 3. 手势优化
- 支持短按+拖动（不需要长按）
- 支持拖动时滚动视图（边缘拖动自动滚动）

### 4. 多选支持
- 支持多选照片后批量拖动插入

## 相关文档
- [插入图片功能说明](./FEATURE_INSERT_PHOTO.md)
- [插入图片 UX 优化](./FEATURE_INSERT_PHOTO_UX_OPTIMIZATION.md)
- [按钮控制优化](./FEATURE_INSERT_PHOTO_BUTTON_CONTROL.md)
