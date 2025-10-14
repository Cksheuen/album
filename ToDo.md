# album

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

### Function

0. 整体考虑使用CustomScrollView实现

1. 顶部模仿微信朋友圈，展示相册封面背景，向下拖拽可以完整展示封面。初始封面占屏幕四分之一高度，封面下半部分展示相册名称等信息。用户向下拖转，全屏展示封面。试着能不能用SliverAppBar的flexiableSpacerBar实现（需要它的动画效果）。

2. 顶部（APPBar）右半边有分组、筛选、排序操作按钮，分组支持按照年月日小时切换，筛选支持根据Tag筛选，排序支持正序倒序。顶部（APPBar）左半边初始状态为空白，当相册往下滚动后（封面消失），Appbar左侧展示当前相册标题。

3. 相册列表页面一行多张图，按照「分组」渲染，分组名称是年月日小时（按照年份分组的时候就是展示年份），整个列表从上到下就是「分组名称」-「照片列表」-「分组名称」-「照片列表」排列。其中分组名称需要实现系顶效果，可以用SliverPersistentHeader实现。但是我希望顶上之展示当先视窗内照片列表所在分组，不堆叠从上到当前位置所有的。

4. 双指缩放能改变一行里图片数量，默认是4

5. 长按图片开启选择模式，上下出现bar，提供对已选择图片的操作。

6. 列表轻轻下拉一点点是刷新，使劲拉到底是展示封面。

7. 相册页面的controller需要实现：

- 使用变量缓存带分组的相册列表数据

- 列表使用分页查询，提供良好的回调接口去加载下一批照片（获取照片接口可以接接受分页查询和查询参数，可以考虑用游标分页还是offset分页）。

- 相册数据会在前台任务云同步，控制器监听同步event，当照片数据更新（插入，删除，修改），需要妥善修改展示在列表数据（需要考虑修改/插入/删除的照片在不在缓存的列表里各种复杂情况）

8. 相册列表渲染一定要注意性能：

- 懒加载相册列表，只渲染可见部分和上下一些区域的部分（Sliver的特性）

- controller数据变更，避免全部重新渲染，最大只能接受group级别的重新渲染

9. 页面支持右侧滚动条，手指放上去长按出现当前group名称，上线滑动滚动条可以带动列表快速滚动。列表懒加载的场景下，滑动到底部1/10的位置触发下一批数据加载。相册列表变更后滚动条也应该同步更新。

10. 双击appbar滚动到顶部。

11. 使用flutter使用Getx框架做状态管理（通过Rx/Obx等能力完成状态更新），尽可能减少使用statefulWidget