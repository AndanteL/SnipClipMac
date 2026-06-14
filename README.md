# SnipClipMac

macOS 截图与贴图工具，功能包括全局热键截图、多显示器区域选择、标注编辑、复制/保存、图片贴到桌面。

## 功能

- **全局快捷键截图** — Carbon HotKey API 注册全局热键，默认 `⇧⌘1`，设置页可自定义
- **多显示器区域选择** — 每块屏幕独立 overlay，拖拽选区，Esc 取消
- **标注编辑** — 浮动工具栏面板（Apple HIG 风格），支持矩形框、椭圆框、画笔、文字、马赛克
- **颜色 / 线宽 / 字号** — 五种标注工具可分别控制描边颜色、线宽、文字字号，修改即时生效
- **撤销 / 重做** — `⌘Z` 撤销，`⌘⇧Z` 重做，工具栏和键盘均可操作
- **复制 / 保存** — PNG 写入系统粘贴板或保存到指定目录，支持 security-scoped bookmark
- **图片贴图** — 将标注后的图片以悬浮窗口贴在桌面上，支持置顶、透明度调节
- **设置页** — 快捷键录制、保存目录选择、默认标注样式、截图后行为配置，配置持久化到本地

## 打开方式

1. 用 Xcode 打开 `Package.swift`，选择 `SnipClipMac` scheme
2. 或者用 Xcode 打开 `SnipClipMac.xcodeproj`
3. 运行前在系统设置 → 隐私与安全性 → 屏幕录制中允许 Xcode 或 SnipClipMac

## 目录

```
Package/
  Package.swift
  Sources/
    SnipClipMacApp/          # 应用入口、菜单栏、生命周期
      SnipClipMacApp.swift
      AppDelegate.swift
    SnipClipCore/            # 核心模型与服务
      AnnotationModel.swift           # 标注工具、样式、数据模型
      AppSettings.swift               # 用户配置模型
      AppSettingsStore.swift          # 配置持久化
      CaptureSession.swift            # 截图会话状态
      HotkeyDefinition.swift          # 快捷键定义与格式化
      HotkeyService.swift             # Carbon 全局快捷键注册
      ImageExportService.swift        # PNG 导出
      PasteboardService.swift         # 系统粘贴板
      ScreenCaptureService.swift      # 屏幕捕获
      ScreenInfoProvider.swift        # 显示器信息
      ScreenshotPermissionController.swift  # 权限控制
    SnipClipUI/              # 用户界面
      AnnotationCanvasView.swift      # 标注绘制（形状、文字、马赛克）
      AnnotationCommand.swift         # 标注 undo/redo 命令模型
      AnnotationEditorViewModel.swift # 编辑窗口状态管理
      AnnotationEditorWindow.swift    # 截图编辑窗口
      AnnotationToolbarPanel.swift    # 浮动工具栏面板
      CaptureCoordinator.swift        # 截图流程协调
      HotkeyRecorderView.swift        # 快捷键录制控件
      PinnedImageWindowController.swift  # 贴图窗口
      SaveLocationPickerView.swift    # 保存目录选择
      SelectionOverlayController.swift   # 选区遮罩控制
      SelectionOverlayView.swift      # 选区遮罩视图
      SelectionOverlayWindow.swift    # 选区遮罩窗口
      SettingsView.swift              # 设置页
      SettingsViewModel.swift         # 设置页状态管理
  Tests/
    SnipClipCoreTests/
      AnnotationStyleTests.swift
      AppSettingsStoreTests.swift
      CaptureSessionTests.swift
      HotkeyDefinitionTests.swift
      ImageExportServiceTests.swift
      PasteboardServiceTests.swift
```

## 技术选型

- **语言：** Swift 6
- **UI：** SwiftUI + AppKit（选区 overlay 和标注编辑窗口使用 AppKit 以获得精确的鼠标控制）
- **屏幕捕获：** CoreGraphics `CGDisplayCreateImage` + 坐标转换
- **全局热键：** Carbon `RegisterEventHotKey` API
- **模块化：** Swift Package（`SnipClipCore` + `SnipClipUI` + `SnipClipMacApp`）
- **配置持久化：** `Application Support/SnipClipMac/settings.json`，支持向后兼容解码

## 开发里程碑

| 阶段 | 状态 |
|------|------|
| Milestone 1：可运行菜单栏应用 + 区域选择 | 已完成 |
| Milestone 2：真实截图数据（ScreenCaptureKit 预备） | 已完成 |
| Milestone 3：编辑与标注（矩形/椭圆/画笔/文字/马赛克） | 已完成 |
| Milestone 4：复制、保存、贴图 | 已完成 |
| Milestone 5：全局快捷键 + 设置页 | 已完成 |
| 后续：设置为正式 Xcode App Target | 已完成 |

## 权限

- **屏幕录制：** `CGPreflightScreenCaptureAccess` / `CGRequestScreenCaptureAccess`，用于捕获屏幕像素
- **文件和文件夹（可选）：** security-scoped bookmark，用户选择的保存目录
