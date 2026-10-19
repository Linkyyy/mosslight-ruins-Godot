# 原生导出

## 引擎与模板

使用 Godot 4.6.3 Standard，安装同版本 Export Templates。工程使用 Compatibility 渲染器和 GDScript，不需要 .NET 或浏览器运行时。

在编辑器 Project → Export 中选择已有预设，或用下面的命令。`builds/` 与签名凭证均被 Git 忽略。

## Linux

```sh
mkdir -p builds/linux
godot --headless --path . --export-release "Linux Desktop" builds/linux/Mosslight.x86_64
```

预设将 PCK 嵌入可执行文件，目标为 x86_64。

## Windows

```sh
mkdir -p builds/windows
godot --headless --path . --export-release "Windows Desktop" builds/windows/Mosslight.exe
```

预设不启用代码签名或外部图标修改工具，目标为 x86_64。公开发行时按发行渠道配置应用图标、签名和版本信息。

## Android

安装与当前 Godot 文档匹配的 Android SDK / OpenJDK，在 Editor Settings → Export → Android 配置本机路径与 debug keystore。工程预设使用 ARM64、横屏和沉浸式窗口，不申请互联网权限。

```sh
mkdir -p builds/android
godot --headless --path . --export-debug "Android" builds/android/Mosslight.apk
```

发行构建需要发行方自己的签名配置；把 keystore 保存在仓库外，不提交 `.export_credentials.cfg`。当前工程没有广告、支付、账户、联网存档或渠道 SDK。

安装后至少检查：启动与返回后台、横屏锁定、刘海/挖孔安全区域、摇杆加跳跃/攻击的多指组合、菜单滚动、冰桥与怪物密集处的帧率、音量与本地存档恢复。

## iOS 与 macOS

游戏逻辑及输入使用跨平台 API，中文字体也已内置。iOS/macOS 的应用包尚未在本工程中构建或验收；请在 macOS 上安装相应 Godot 模板并配置 Apple 工具链和签名，再建立平台导出预设。

## 资源包验证

即使没有桌面导出模板，也可以生成并使用引擎运行 PCK，检查打包后的资源路径：

```sh
mkdir -p builds
godot --headless --path . --export-pack "Linux Desktop" builds/Mosslight.pck
godot --main-pack builds/Mosslight.pck
```

PCK 是需要 Godot 引擎加载的游戏资源包，不是独立安装程序。独立应用使用前面的正式平台导出步骤。
