# ScreenshotToNotes - 截图笔记

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

截图后自动提取文字，智能分类保存到 Apple 备忘录。

## 功能特性

- ✨ **自动触发**：通过快捷指令自动化，截图后自动处理
- 🔍 **智能提取**：使用 Vision OCR 识别中英文文字
- 🏷️ **智能分类**：基于内容自动分类（灵感/方法/待办/单据/联系人/收藏）
- ⚡ **轻量筛选**：弹出分类选择框，支持超时自动保存
- 📝 **结构化保存**：提取标题、摘要、标签、实体信息
- 📂 **文件夹映射**：自动保存到对应的备忘录文件夹
- 🔄 **后备监控**：PhotoKit 监控作为补漏方案

## 系统要求

- iOS 17.0 或更高版本
- Xcode 15.0 或更高版本
- Swift 5.9 或更高版本

## 快速开始

### 1. 编译项目

```bash
cd ScreenshotToNotes
open ScreenshotToNotes.xcodeproj
```

在 Xcode 中：
1. 选择你的开发团队（Signing & Capabilities）
2. 连接 iOS 设备或选择模拟器
3. 点击 Run (⌘R)

### 2. 首次设置

#### 步骤 1：导入快捷指令

App 首次启动会引导你导入官方快捷指令：

1. 点击「导入快捷指令」按钮
2. 跳转到快捷指令 App
3. 点击「添加快捷指令」

**快捷指令内容：**
```
获取最新截图
  ↓
运行 App Intent「处理最新截图」
  ↓
（App 自动打开并显示分类选择框）
```

#### 步骤 2：创建自动化

1. 打开「快捷指令」App
2. 进入「自动化」标签页
3. 点击右上角 `+` → 「创建个人自动化」
4. 选择「截取屏幕时」
5. 点击「添加操作」
6. 搜索并选择刚导入的「截图存到备忘录」快捷指令
7. **重要**：关闭「运行前询问」开关
8. 点击「完成」

#### 步骤 3：授予权限

- **照片权限**：用于读取新截图（必需）
- **通知权限**：用于显示「已保存」提示（可选）

#### 步骤 4：试运行

1. 按音量+ 和电源键截图
2. 应该自动弹出分类选择框
3. 选择分类或等待超时自动保存
4. 打开备忘录 App 查看保存结果

### 3. 备选触发方式（可选）

除了「截取屏幕时」自动化，还可以设置：

#### 辅助触控（AssistiveTouch）

1. 设置 → 辅助功能 → 触控 → 辅助触控
2. 自定义顶层菜单，添加「截屏」
3. 或添加「快捷指令」→ 选择「截图存到备忘录」

#### 背面轻点（Back Tap）

1. 设置 → 辅助功能 → 触控 → 背面轻点
2. 选择「轻点两下」或「轻点三下」
3. 选择「快捷指令」→「截图存到备忘录」

## 使用说明

### 主要流程

```
截图（系统） 
  ↓
自动化触发快捷指令
  ↓
App 打开 + OCR 识别
  ↓
分类选择框（6秒倒计时）
  ↓
保存到备忘录对应文件夹
```

### 分类说明

| 分类 | 说明 | 触发关键词 | 备忘录文件夹 |
|------|------|-----------|-------------|
| 灵感 | 金句、观点、想法 | 名言、金句、观点、灵感 | 灵感 |
| 方法 | 教程、步骤、攻略 | 教程、步骤、方法、如何 | 方法 |
| 待办 | 任务、提醒事项 | 待办、任务、需要、记得、DDL | 待办 |
| 单据 | 订单、发票、收据 | 订单号、支付、金额、发票 | 单据 |
| 联系人 | 电话、微信、邮箱 | 电话、微信、邮箱、地址 | 联系人 |
| 收藏 | 商品、产品信息 | 价格、购买、商品、产品 | 收藏 |
| 收件箱 | 低置信度内容 | （默认分类） | 收件箱 |

### 笔记格式

保存到备忘录的笔记包含：

```markdown
# 标题（第一行或摘要）

> 摘要（内容概览）

**类别：** 灵感
**标签：** #截图收藏 #灵感 #其他标签
**截取时间：** 2024年9月6日 12:00
**保存时间：** 2024年9月6日 12:01

---

正文内容（OCR 识别的完整文本）

---

**结构化信息**
- 日期：2024-09-06
- 金额：¥299.00
- 联系方式：138****5678
- 编号：ORDER123456

**来源：** 用户截图（疑似抖音/微信/Twitter等）
```

### 设置选项

#### 自动保存

- **启用自动保存**：筛选框超时后自动保存
- **超时时间**：3-15秒可调（默认6秒）
- **保存前预览**：每次都显示筛选框
- **包含图片**：在笔记中附加截图缩略图

#### 分类映射

可自定义每个分类对应的备忘录文件夹名称。

#### 相册监控

PhotoKit 监控作为后备方案，当快捷指令未触发时补救。

## 架构说明

### 模块结构

```
ScreenshotToNotes/
├── App/
│   ├── ScreenshotToNotesApp.swift    # App 入口
│   ├── ContentView.swift             # 主界面
│   └── Models.swift                  # 数据模型
├── Onboarding/
│   └── OnboardingView.swift          # 引导界面
├── Capture/
│   ├── CaptureManager.swift          # 截图处理管理器
│   └── PhotoKitMonitor.swift         # 相册监控
├── Extract/
│   ├── OCRService.swift              # OCR 文字识别
│   └── CategoryClassifier.swift      # 分类器
├── FilterUI/
│   └── FilterSheetView.swift         # 分类选择界面
├── Notes/
│   └── NotesWriter.swift             # 备忘录写入
├── History/
│   └── HistoryView.swift             # 历史记录
├── Settings/
│   └── SettingsView.swift            # 设置界面
└── AppIntents/
    └── ProcessScreenshotIntent.swift # App Intent
```

### 核心流程

1. **触发**：快捷指令自动化调用 App Intent
2. **捕获**：获取最新截图（PhotoKit）
3. **识别**：Vision OCR 识别文字
4. **分类**：启发式分类器判断类别
5. **展示**：弹出筛选框供用户确认
6. **保存**：通过 URL Scheme 写入备忘录

### 关键技术

- **SwiftUI**：全部界面
- **Vision Framework**：OCR 文字识别
- **PhotoKit**：访问相册和截图
- **App Intents**：快捷指令集成
- **UserDefaults**：本地数据持久化

## Apple Notes 集成方案

### 当前实现：URL Scheme

使用 `mobilenotes://` URL Scheme 创建笔记。

**优点：**
- 无需私有 API
- 简单可靠
- App Store 审核友好

**限制：**
- 无法指定文件夹（iOS 限制）
- 无法获取创建的笔记 ID
- 无法更新已有笔记

**代码示例：**
```swift
let url = "mobilenotes://action=append&note=\(encodedContent)"
UIApplication.shared.open(URL(string: url)!)
```

### 备选方案（未实现）

#### 1. EventKit（不适用）
EventKit 仅支持日历和提醒事项，**不支持 Notes**。

#### 2. 分享扩展
可以通过分享到备忘录，但需要用户手动触发，不符合「自动」需求。

#### 3. 第三方库
- [NoteKit](https://github.com/example/notekit)（假设）：可能依赖私有 API
- **风险**：审核被拒

### 文件夹映射说明

由于 iOS 限制，无法通过公开 API 指定备忘录文件夹。当前实现：

1. 笔记标题包含分类标识：`[灵感] 标题`
2. 用户可在备忘录 App 中手动移动
3. 文档中说明此限制

## 测试

### 运行单元测试

```bash
# Xcode
⌘U

# 命令行
xcodebuild test -project ScreenshotToNotes.xcodeproj -scheme ScreenshotToNotes -destination 'platform=iOS Simulator,name=iPhone 15'
```

### 测试覆盖

- ✅ 分类器测试（CategoryClassifierTests）
  - 任务分类
  - 单据分类
  - 联系人分类
  - 来源识别
- ✅ 实体提取测试（ScreenshotToNotesTests）
  - 日期提取
  - 金额提取
  - 联系方式提取

### 手动测试清单

- [ ] 首次引导流程
- [ ] 快捷指令导入
- [ ] 自动化触发
- [ ] 相册选择
- [ ] 分类选择框
- [ ] 超时自动保存
- [ ] 备忘录写入
- [ ] 历史记录
- [ ] 设置修改

## 已知限制

### 系统限制

1. **无法指定备忘录文件夹**
   - iOS 公开 API 不支持
   - 用户需手动移动笔记

2. **快捷指令「运行前询问」**
   - 首次设置容易遗漏关闭
   - 引导界面有详细说明

3. **PhotoKit 延迟**
   - 相册监控可能有1-2秒延迟
   - 快捷指令自动化是主路径

### App 限制

1. **分类准确度**
   - 基于启发式规则，非 LLM
   - 置信度低时默认「收件箱」

2. **OCR 识别**
   - 依赖 Vision Framework
   - 手写文字识别率较低
   - 复杂排版可能错乱

3. **来源识别**
   - 基于关键词匹配
   - 准确度取决于截图内容

## 故障排查

### 自动化不触发

1. 检查「快捷指令」App → 自动化
2. 确认「截取屏幕时」自动化已创建
3. 确认已**关闭「运行前询问」**
4. 尝试删除自动化重新创建

### 无法访问截图

1. 检查设置 → ScreenshotToNotes → 照片权限
2. 确认已授权「所有照片」或「选中的照片」

### 备忘录未创建

1. 检查备忘录 App 是否可正常打开
2. 尝试手动在备忘录创建一条笔记测试
3. 查看 App 历史记录中的错误信息

### 分类不准确

1. 在设置中调整类别映射
2. 手动选择正确分类
3. 可提交反馈帮助改进

## 路线图

### v1.0（当前）

- [x] 快捷指令集成
- [x] OCR 识别
- [x] 启发式分类
- [x] 备忘录写入
- [x] 历史记录
- [x] 设置界面

### v1.1（计划）

- [ ] 批量处理
- [ ] LLM 分类（可选）
- [ ] 自定义分类
- [ ] iCloud 同步设置
- [ ] iPad 适配优化

### v1.2（计划）

- [ ] 分享扩展
- [ ] Siri 支持
- [ ] Widget 小组件
- [ ] macOS 版本

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 致谢

- [Vision Framework](https://developer.apple.com/documentation/vision) - OCR 识别
- [App Intents](https://developer.apple.com/documentation/appintents) - 快捷指令集成
- [PhotoKit](https://developer.apple.com/documentation/photokit) - 相册访问

---

**注意**：本项目为 MVP 实现，Notes API 集成受 iOS 系统限制。文件夹指定功能依赖未来 Apple 可能提供的公开 API。
