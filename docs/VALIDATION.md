# 当前验证记录

引擎：Godot 4.6.3.stable.official，Linux headless，Compatibility 项目配置。

## 已执行

- 原生编辑器资源导入与 GDScript 编译，未出现脚本解析/加载错误。
- `python3 tools/check.py`：**110 / 110** 项引擎内检查通过；运行日志没有 SCRIPT ERROR、ERROR 或泄漏警告。
- 使用 Linux Desktop 预设成功导出原生 PCK。
- 使用 Godot `--main-pack` 从导出的 PCK 启动并进入新旅程，运行 180 帧后正常退出，无运行时错误。

测试使用实际 CharacterBody2D、Area2D、物理射线和原生 Control，而非网页或模拟 DOM。覆盖新档门控、实际拾取、跑跳/缓冲/离地宽容、近战前摇与单击去重、连击伤害、箭矢与炸弹、元素机关、装备、二段跳、所有菜单、两种横屏尺寸、多指触摸、竖屏暂停、首领、死亡与复活、损坏存档恢复及旧档归一化。

所有测试旅程使用 `.user_test/profile/`。发布资源不包含测试和开发工具，也不包含本地存档或签名凭证。

## 验证范围

headless 验证能检查实际引擎逻辑、节点和布局尺寸，不能代替原生窗口画面、设备音频、手柄手感、手机触屏体验与 GPU 性能检查。当前环境未提供可用的图形显示服务；这些实机验收仍需在目标设备进行。

当前生成的 PCK 需要 Godot 引擎加载。Windows/Linux 独立可执行文件、Android APK 及 iOS 应用包尚未在此环境构建或验证，需要相应导出模板、SDK 与签名工具链。没有把 PCK 声称为独立安装包。
