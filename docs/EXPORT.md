# 原生导出

## 自动打包与下载

工作流 `.github/workflows/native-release.yml` 在 `main` 更新 `release/version.txt` 或工作流时构建，也可通过 Actions 页面手动运行。构建使用 Godot 4.6.3、Java 17、Android SDK 和 NSIS，先运行原生回归，再检查 APK 签名和 Windows 安装/启动/卸载；所有作业成功后发布 GitHub 预览 Release。

成品为 Android ARM64 APK、Windows x64 安装程序、Windows 免安装 ZIP，附 SHA-256 校验文件和源码提交信息。Windows 安装按当前用户进行，无需管理员权限，卸载保留用户存档。安装路径和开始菜单都由安装向导处理。

预览 APK 使用缓存保存的开发测试 keystore；它不是正式渠道发行密钥。缓存失效可能改变测试证书，届时旧测试版不能直接覆盖安装，请先导出存档再卸载旧版。正式发行应改用所有者持久保管的签名密钥和仓库 Secrets，不能把私钥提交到源码或公开 Release。Windows 当前未做商业代码签名。

构建会通过 `tools/prepare_distribution.gd` 从实际 Godot 引擎导出 MIT 与第三方声明到 `assets/licenses/`，并包含在 APK 与桌面版内。该目录的生成文件被 Git 忽略。

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
