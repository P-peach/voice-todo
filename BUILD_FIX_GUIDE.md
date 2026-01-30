# 构建错误修复指南

## 问题描述
sqlite3 包在下载 native 库时失败：
```
HttpException: Connection closed before full header was received
uri = https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.1.3/libsqlite3.arm64.macos.dylib
```

这是网络连接问题，不是代码错误。

## 解决方案

### 方案 1：重试构建（推荐）
网络问题可能是暂时的，直接重试：

```bash
flutter clean
flutter pub get
flutter run -d macos
```

### 方案 2：使用代理或 VPN
如果你在中国大陆，GitHub 下载可能不稳定，建议：
1. 开启 VPN 或代理
2. 然后重新运行：
```bash
flutter clean
flutter pub get
flutter run -d macos
```

### 方案 3：手动下载并放置文件
如果网络持续失败，可以手动下载：

1. 使用浏览器或其他下载工具下载文件：
   https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.1.3/libsqlite3.arm64.macos.dylib

2. 将下载的文件放到正确位置（构建时会自动创建目录）

3. 重新运行构建

### 方案 4：清理缓存后重试
```bash
# 清理 Flutter 缓存
flutter clean

# 清理 pub 缓存（可选，会重新下载所有依赖）
rm -rf ~/.pub-cache/hosted/pub.dev/sqlite3-3.1.3

# 重新获取依赖
flutter pub get

# 运行应用
flutter run -d macos
```

### 方案 5：检查网络连接
```bash
# 测试是否能访问 GitHub
curl -I https://github.com

# 如果无法访问，配置代理（示例）
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890

# 然后重新构建
flutter run -d macos
```

## 验证代码没有问题

我已经验证过，你的代码本身没有语法错误：
- ✅ `lib/screens/home/home_screen.dart` - 无错误
- ✅ `lib/screens/main_screen.dart` - 无错误  
- ✅ `lib/theme/app_theme.dart` - 无错误
- ✅ `lib/theme/app_colors.dart` - 无错误

深色模式优化的代码都是正确的，只是构建时下载依赖失败。

## 推荐步骤

1. **先尝试方案 1**（最简单）
2. 如果失败，检查网络是否能访问 GitHub
3. 如果不能访问 GitHub，使用**方案 2**（VPN/代理）
4. 如果还是失败，尝试**方案 4**（清理缓存）

## 注意事项

- 这个错误与我的代码修改**无关**
- 即使回退到之前的代码，只要重新构建也会遇到同样的问题
- 这是 Flutter 构建 native 依赖时的常见网络问题
