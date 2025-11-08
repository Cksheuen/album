# Hero 动画优化完整文档

> 最后更新：2025-10-21  
> 状态：✅ 已完成

## 目录

- [功能概述](#功能概述)
- [方案迭代历史](#方案迭代历史)
- [技术实现](#技术实现)
- [问题修复记录](#问题修复记录)
- [最佳实践](#最佳实践)

---

## 功能概述

### 核心价值

实现照片从网格到全屏的流畅过渡动画，提供类似 iOS 照片应用的高质量视觉体验。

### 动画效果

1. **位置过渡**：照片从网格位置平滑移动到屏幕中央
2. **尺寸过渡**：照片从小方块平滑放大到全屏
3. **BoxFit 过渡**：从裁剪状态（cover）平滑过渡到完整显示（contain）
4. **背景过渡**：背景从透明渐变到黑色

---

## 方案迭代历史

### 版本 1.0：基础 Hero 动画（2025-10-19）

**实现：**
```dart
// 网格中
Hero(
  tag: 'album_photo_${photo.path}',
  child: Image(...),
)

// 全屏中
Hero(
  tag: 'album_photo_$imagePath',
  child: InteractiveViewer(...),
)
```

**问题：**
- 动画生硬，缺乏曲线
- 没有自定义飞行效果
- 性能一般

### 版本 2.0：添加动画曲线（2025-10-20）

**改进：**
```dart
PageRouteBuilder(
  transitionDuration: Duration(milliseconds: 400),
  pageBuilder: (context, animation, secondaryAnimation) {
    return FadeTransition(
      opacity: animation,
      child: Scaffold(...),
    );
  },
)
```

**优势：**
- 背景淡入更自然
- 动画时长可控
- 但仍然缺乏飞行效果定制

### 版本 3.0：添加 flightShuttleBuilder（2025-10-20）

**关键改进：**
```dart
Hero(
  tag: heroTag,
  flightShuttleBuilder: (
    flightContext,
    animation,
    flightDirection,
    fromHeroContext,
    toHeroContext,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: flightDirection == HeroFlightDirection.push
          ? Curves.easeOutCubic  // 打开：快速启动，慢慢减速
          : Curves.easeInCubic,   // 关闭：慢慢启动，快速结束
    );
    
    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: SmartImage(
            path: imageAsset,
            isNetwork: imageAsset.startsWith('http'),
            fit: BoxFit.contain,
          ),
        );
      },
    );
  },
  child: InteractiveViewer(...),
)
```

**优势：**
- 自定义飞行曲线
- 打开和关闭使用不同曲线
- 动画更加流畅自然

**问题：**
- Hero tag 不匹配导致动画失效

### 版本 3.1：修复 Hero Tag 不匹配（2025-10-20）

**问题：**
```dart
// 网格中
final heroTag = 'album_photo_${photo.path}_${photo.date.millisecondsSinceEpoch}';

// 全屏中
final heroTag = 'album_photo_$imagePath';

// 结果：两个 tag 不相等，Hero 动画失效 ❌
```

**解决方案：**
```dart
// 统一使用路径作为 tag
final uniqueKey = photo.path;
final heroTag = 'album_photo_$uniqueKey';
```

**效果：**
- Hero 动画正常工作 ✅
- 图片有平滑的位置和尺寸过渡

### 版本 4.0：优化 BoxFit 过渡（2025-10-21）

**问题：**
```
网格：BoxFit.cover（裁剪）
   ↓ Hero 动画
全屏：BoxFit.contain（完整）
   ↓ 结果
图片内容突然从裁剪变成完整 ❌
```

**解决方案：**
```dart
flightShuttleBuilder: (
  flightContext,
  animation,
  flightDirection,
  fromHeroContext,
  toHeroContext,
) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: flightDirection == HeroFlightDirection.push
        ? Curves.easeOutCubic
        : Curves.easeInCubic,
  );
  
  return AnimatedBuilder(
    animation: curvedAnimation,
    builder: (context, child) {
      final progress = curvedAnimation.value;
      
      // 根据动画方向和进度决定 BoxFit
      final BoxFit fit;
      if (flightDirection == HeroFlightDirection.push) {
        // 打开：在 70% 处切换
        fit = progress < 0.7 ? BoxFit.cover : BoxFit.contain;
      } else {
        // 关闭：在 30% 处切换
        fit = progress > 0.3 ? BoxFit.contain : BoxFit.cover;
      }
      
      return Material(
        color: Colors.transparent,
        child: SmartImage(
          path: imageAsset,
          isNetwork: imageAsset.startsWith('http'),
          fit: fit,  // ✅ 动态 BoxFit
        ),
      );
    },
  );
},
```

**效果：**
- 打开时：前 70% 保持裁剪，后 30% 显示完整
- 关闭时：前 30% 显示完整，后 70% 恢复裁剪
- 过渡更加自然，不易察觉

### 版本 4.1：缩短动画时长（2025-10-21）

**优化：**
```dart
// 从 400ms 缩短到 350ms
transitionDuration: Duration(milliseconds: 350),
reverseTransitionDuration: Duration(milliseconds: 350),
```

**原因：**
- 400ms 稍显拖沓
- 350ms 更加干脆利落
- 配合 BoxFit 切换，感觉刚刚好

---

## 技术实现

### 完整代码

```dart
void _showFullScreenImage(
  BuildContext context,
  String imageAsset,
  String heroTag, {
  VoidCallback? onClosed,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      transitionDuration: Duration(milliseconds: 350),
      reverseTransitionDuration: Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  print('分享图片: $imageAsset');
                },
              ),
            ],
          ),
          body: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: Hero(
                tag: heroTag,
                flightShuttleBuilder: (
                  BuildContext flightContext,
                  Animation<double> animation,
                  HeroFlightDirection flightDirection,
                  BuildContext fromHeroContext,
                  BuildContext toHeroContext,
                ) {
                  // 应用动画曲线
                  final curvedAnimation = CurvedAnimation(
                    parent: animation,
                    curve: flightDirection == HeroFlightDirection.push
                        ? Curves.easeOutCubic
                        : Curves.easeInCubic,
                  );
                  
                  return AnimatedBuilder(
                    animation: curvedAnimation,
                    builder: (context, child) {
                      final progress = curvedAnimation.value;
                      
                      // 动态 BoxFit
                      final BoxFit fit;
                      if (flightDirection == HeroFlightDirection.push) {
                        fit = progress < 0.7 ? BoxFit.cover : BoxFit.contain;
                      } else {
                        fit = progress > 0.3 ? BoxFit.contain : BoxFit.cover;
                      }
                      
                      return Material(
                        color: Colors.transparent,
                        child: SmartImage(
                          path: imageAsset,
                          isNetwork: imageAsset.startsWith('http'),
                          fit: fit,
                        ),
                      );
                    },
                  );
                },
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: SmartImage(
                    path: imageAsset,
                    isNetwork: imageAsset.startsWith('http'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  ).then((_) {
    onClosed?.call();
  });
}
```

### 关键技术点

#### 1. Hero Tag 统一

```dart
// 网格和全屏使用相同的 tag 生成逻辑
final heroTag = 'album_photo_${photo.path}';
```

#### 2. 动画曲线

```dart
// easeOutCubic: 快速启动，慢慢减速（打开）
// easeInCubic: 慢慢启动，快速结束（关闭）
curve: flightDirection == HeroFlightDirection.push
    ? Curves.easeOutCubic
    : Curves.easeInCubic
```

#### 3. BoxFit 切换时机

```dart
// 打开：70% 处切换（大部分时间保持裁剪）
// 关闭：30% 处切换（快速恢复裁剪）
fit = progress < 0.7 ? BoxFit.cover : BoxFit.contain;
```

#### 4. Material Wrapper

```dart
// Hero 飞行需要 Material 包裹
Material(
  color: Colors.transparent,
  child: SmartImage(...),
)
```

---

## 问题修复记录

### Bug #1: Hero 动画不工作

**时间：** 2025-10-20

**现象：**
- 点击照片时，图片没有从网格位置过渡
- 图片直接出现在全屏位置
- 缺少平滑的移动和缩放

**根本原因：**
```dart
// 网格中的 tag
'album_photo_/path/to/image.jpg_1729327200000'
//                                ↑ 包含时间戳

// 全屏中的 tag
'album_photo_/path/to/image.jpg'
//                                ↑ 没有时间戳

// 两个 tag 不相等 → Hero 动画失效
```

**解决方案：**
```dart
// 统一使用路径作为唯一标识
final uniqueKey = photo.path;
final heroTag = 'album_photo_$uniqueKey';
```

**参考文档：**
- `docs/bugfixes/FIX_HERO_TAG_MISMATCH.md`

### Bug #2: BoxFit 突然切换

**时间：** 2025-10-21

**现象：**
- 网格中照片是正方形（裁剪）
- 全屏时照片是完整的（含黑边）
- Hero 动画时图片内容突然变化

**问题：**
```
网格：BoxFit.cover
  ↓ Hero 动画中
  ? BoxFit 没有过渡
  ↓
全屏：BoxFit.contain
```

**解决方案：**
```dart
// 根据动画进度动态调整 BoxFit
final progress = curvedAnimation.value;
final fit = progress < 0.7 ? BoxFit.cover : BoxFit.contain;
```

**参考文档：**
- `docs/improvements/HERO_ANIMATION_BOXFIT_TRANSITION.md`

---

## 最佳实践

### 1. Hero Tag 设计原则

✅ **推荐：使用唯一且稳定的标识**
```dart
Hero(tag: 'album_photo_${photo.path}', ...)
Hero(tag: 'album_photo_${photo.id}', ...)
```

❌ **避免：添加时间戳等易变信息**
```dart
Hero(tag: 'photo_${photo.path}_${timestamp}', ...)  // ❌
Hero(tag: 'photo_${photo.path}_${index}', ...)      // ❌
```

### 2. 动画曲线选择

| 场景 | 推荐曲线 | 理由 |
|------|---------|------|
| 打开动画 | `Curves.easeOutCubic` | 快速启动，慢慢减速，响应快 |
| 关闭动画 | `Curves.easeInCubic` | 慢慢启动，快速结束，干脆利落 |
| 弹性效果 | `Curves.elasticOut` | 有回弹感，适合特殊场景 |
| 线性 | `Curves.linear` | 匀速，机械感，不推荐 |

### 3. BoxFit 切换时机

| 切换点 | 适用场景 | 效果 |
|--------|---------|------|
| 50% | 快速切换 | 切换明显 |
| **70%** | **推荐** | **平衡最佳** |
| 80% | 保守切换 | 裁剪时间长 |

### 4. 动画时长建议

| 时长 | 适用场景 | 感受 |
|-----|---------|------|
| 250ms | 简单过渡 | 很快 |
| **350ms** | **推荐** | **刚好** |
| 400ms | 标准过渡 | 稍慢 |
| 500ms+ | 复杂动画 | 拖沓 |

### 5. 性能优化

```dart
// ✅ 使用 const 构造函数
const Hero(tag: 'fixed_tag', child: ...)

// ✅ 避免在飞行中做复杂计算
flightShuttleBuilder: (...) {
  // 只做必要的动画插值
  // 避免复杂的业务逻辑
}

// ✅ 使用缓存图片
SmartImage(
  path: photo.path,
  fit: BoxFit.cover,
  // 内部应该使用 CachedNetworkImage
)
```

---

## 动画时序对比

### 打开全屏（Push）

```
Progress:  0%        30%       50%       70%       100%
           ├─────────┼─────────┼─────────┼─────────┤
位置:      网格 ───────────────────────────────→ 中央
尺寸:      小 ────────────────────────────────→ 大
BoxFit:    cover ──────────────────────────> contain
           └──────── 保持裁剪 ────────┘    └─ 完整 ─┘
                                          ↑ 切换点
曲线:      easeOutCubic (快启动→慢减速)
背景:      透明 ────────────────────────────→ 黑色
```

### 关闭全屏（Pop）

```
Progress:  0%        30%       50%       70%       100%
           ├─────────┼─────────┼─────────┼─────────┤
位置:      中央 ───────────────────────────────→ 网格
尺寸:      大 ────────────────────────────────→ 小
BoxFit:    contain ─────> cover ──────────────────────
           └─ 完整 ─┘    └──────── 保持裁剪 ────────┘
                     ↑ 切换点
曲线:      easeInCubic (慢启动→快结束)
背景:      黑色 ────────────────────────────→ 透明
```

---

## 相关文档

### 优化文档
- `docs/improvements/OPTIMIZE_FULLSCREEN_IMAGE_ANIMATION.md` - 初始优化
- `docs/improvements/OPTIMIZE_FULLSCREEN_IMAGE_HERO.md` - Hero 动画优化
- `docs/improvements/QUICK_OPTIMIZE_FULLSCREEN_ANIMATION.md` - 快速优化
- `docs/improvements/HERO_ANIMATION_BOXFIT_TRANSITION.md` - BoxFit 过渡

### 修复文档
- `docs/bugfixes/FIX_HERO_TAG_MISMATCH.md` - Hero Tag 不匹配

### 指南文档
- `docs/improvements/QUICK_GUIDE_FULLSCREEN_IMAGE.md` - 快速指南

---

## 未来规划

### 已实现 ✅
- [x] 基础 Hero 动画
- [x] 自定义动画曲线
- [x] Hero Tag 统一
- [x] BoxFit 平滑过渡
- [x] 动画时长优化

### 待实现 📋
- [ ] 手势控制关闭（下滑关闭）
- [ ] 多图切换动画
- [ ] 视频缩略图过渡
- [ ] 3D Transform 效果
- [ ] 共享元素转场（多个元素）

---

*最后更新：2025-10-21*
