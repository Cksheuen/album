# 图片插入功能 - 权限配置指南

## iOS 配置

需要在 `ios/Runner/Info.plist` 中添加相册访问权限：

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问您的相册以选择要插入的图片</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要访问您的相册以添加图片</string>
```

## Android 配置

### 1. AndroidManifest.xml

在 `android/app/src/main/AndroidManifest.xml` 中添加权限：

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 读取外部存储权限 -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    
    <!-- Android 13+ 使用的新权限 -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    
    <application>
        ...
    </application>
</manifest>
```

### 2. build.gradle

确保 `android/app/build.gradle` 中的 `minSdkVersion` 至少为 21：

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // 至少21
        targetSdkVersion flutter.targetSdkVersion
    }
}
```

## 运行时权限处理

应用会在首次使用相册选择功能时自动请求权限。`image_picker` 包已经处理了权限请求流程。

## 测试权限

### iOS
1. 首次点击「从相册选择」会弹出权限请求对话框
2. 用户可以选择「允许」或「不允许」
3. 如果用户拒绝，后续可在系统设置中修改权限

### Android
1. Android 13+ 会弹出新的照片选择器，无需额外权限
2. Android 13以下会请求存储权限
3. 权限拒绝后可在应用设置中修改

## 常见问题

### Q: iOS 模拟器无法选择图片？
A: 需要在模拟器的相册中先添加一些图片。可以通过Safari保存图片到相册。

### Q: Android 权限被拒绝后如何重新请求？
A: 使用 `permission_handler` 包可以引导用户到应用设置页面。

### Q: 需要相机权限吗？
A: 当前版本只支持从相册选择，不需要相机权限。未来如果添加拍照功能，需要添加相机权限。

## 完整示例

### ios/Runner/Info.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 其他配置 -->
    
    <!-- 相册访问权限 -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>需要访问您的相册以选择要插入的图片</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>需要访问您的相册以添加图片</string>
    
    <!-- 其他配置 -->
</dict>
</plist>
```

### android/app/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    
    <application
        android:label="album"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- Activity 配置 -->
    </application>
</manifest>
```

## 更新日期
2025年10月17日
