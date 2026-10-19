原生 Godot 测试版，可离线运行，无需安装 Godot。

- **Android**：下载 `Android-arm64.apk`，在安卓手机上安装，横屏游玩。
- **Windows 安装版**：下载 `Windows-x64-Setup.exe`，按向导安装，开始菜单或桌面启动。
- **Windows 免安装版**：下载 `Windows-x64-Portable.zip`，完整解压后运行 `Mosslight.exe`。

包含六区探索、元素机关、武器装备、首领、全屏地图与背包、触屏/键盘/手柄操作和本地存档。能力和武器需要探索获得。

Android 使用开发测试签名；Windows 尚未购买代码签名证书，系统可能显示发布者未知。APK 已检查包信息和签名；Windows 安装、原生启动和卸载由自动化验收。尚未完成安卓真机及所有硬件兼容性测试。

`SHA256SUMS.txt` 提供文件校验，`BUILD-INFO.json` 记录对应源码。Windows 卸载保留用户存档。
