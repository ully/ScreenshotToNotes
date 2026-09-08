# 技术实现说明

## 项目概览

本文档详细说明 ScreenshotToNotes iOS MVP 的技术实现细节。

## 架构设计

### 模块划分

```
App Layer (应用层)
├── ScreenshotToNotesApp.swift    # App 生命周期
├── ContentView.swift              # 主界面
├── Models.swift                   # 数据模型
└── LocalizationStrings.swift     # 本地化字符串

Onboarding Layer (引导层)
└── OnboardingView.swift           # 5 步引导流程

Capture Layer (捕获层)
├── CaptureManager.swift           # 截图处理协调器
└── PhotoKitMonitor.swift          # 相册监控服务

Extract Layer (提取层)
├── OCRService.swift               # Vision OCR 封装
└── CategoryClassifier.swift       # 分类器（启发式规则）

FilterUI Layer (筛选层)
└── FilterSheetView.swift          # 分类选择界面

Notes Layer (笔记层)
└── NotesWriter.swift              # Apple Notes 写入

History Layer (历史层)
└── HistoryView.swift              # 历史记录展示

Settings Layer (设置层)
└── SettingsView.swift             # 设置管理

AppIntents Layer (意图层)
└── ProcessScreenshotIntent.swift  # 快捷指令集成
```

### 数据流

```
用户截图
  ↓
快捷指令自动化触发
  ↓
ProcessScreenshotIntent (App Intent)
  ↓
CaptureManager.getLatestScreenshot()  [PhotoKit]
  ↓
CaptureManager.processScreenshot()
  ├─→ OCRService.recognizeText()     [Vision]
  ├─→ CategoryClassifier.classify()   [启发式]
  └─→ 返回 ExtractedContent
  ↓
ContentView 显示 FilterSheetView
  ↓
用户选择分类或超时自动保存
  ↓
NotesWriter.writeNote()              [URL Scheme]
  ↓
Apple Notes 创建笔记
```

## 核心组件详解

### 1. CaptureManager

**职责：** 协调截图处理流程

**关键方法：**
- `getLatestScreenshot() -> UIImage?`：从相册获取最新截图
- `processScreenshot(_ image: UIImage) -> ExtractedContent`：完整处理流程
- `recordSuccess()/recordFailure()`：记录处理结果

**状态管理：**
- `@Published var recentRecords: [ProcessingRecord]`
- `@Published var isProcessing: Bool`
- `settings: AppSettings`

### 2. OCRService

**技术：** Vision Framework

**支持语言：**
- 简体中文 (`zh-Hans`)
- 繁体中文 (`zh-Hant`)
- 英文 (`en-US`)

**识别流程：**
```swift
1. VNRecognizeTextRequest 配置
   - recognitionLevel: .accurate
   - usesLanguageCorrection: true

2. VNImageRequestHandler 执行

3. 结果处理
   - 拼接识别文本
   - 提取标题（首行）
   - 生成摘要（前 100 字）
   - 实体提取
```

**实体提取规则：**

| 实体类型 | 正则表达式示例 | 说明 |
|---------|---------------|------|
| 日期 | `\d{4}[-年]\d{1,2}[-月]\d{1,2}[日]?` | 支持多种格式 |
| 金额 | `¥\s?\d+(?:,\d{3})*(?:\.\d{2})?` | 人民币、美元 |
| 电话 | `1[3-9]\d{9}` | 中国大陆手机号 |
| 邮箱 | `[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}` | 标准格式 |
| 微信号 | `微信[：:号]?\s*([A-Za-z0-9_-]+)` | 关键词匹配 |
| 链接 | `https?://[^\s]+` | HTTP/HTTPS |

### 3. CategoryClassifier

**设计模式：** Protocol-based，便于后续替换 LLM

```swift
protocol CategoryClassifierProtocol {
    func classify(text: String) -> ClassificationResult
}
```

**分类逻辑：**

1. **来源识别**
   - 关键词匹配（抖音、Twitter、微信等）
   - 返回 `SourceGuess` 枚举

2. **分类打分**
   ```swift
   categories = [
       (.task, ["待办", "todo", "任务"], weight: 2.0),
       (.receipt, ["订单", "支付", "金额"], weight: 2.0),
       (.contact, ["电话", "微信", "邮箱"], weight: 2.0),
       (.howto, ["教程", "步骤", "方法"], weight: 1.5),
       (.insight, ["名言", "金句", "观点"], weight: 1.2),
       (.product, ["价格", "购买", "商品"], weight: 1.5)
   ]
   ```

3. **置信度计算**
   ```swift
   confidence = min(0.5 + matchCount * 0.15, 0.95)
   ```

4. **标签提取**
   - Hashtag 提取：`#[\w\u4e00-\u9fa5]+`
   - 主题关键词匹配

### 4. FilterSheetView

**UI 特性：**
- SwiftUI Sheet 展示
- LazyVGrid 布局（3 列）
- 实时倒计时显示
- 推荐分类高亮（星标）

**交互逻辑：**
```swift
// 倒计时
Timer.scheduledTimer(withTimeInterval: 1.0) {
    if remainingTime > 0 {
        remainingTime -= 1
    } else {
        saveNow()  // 超时自动保存
    }
}

// 用户选择
Button { selectedCategory = .task } // 立即保存

// 取消
Button { onSelection(nil) }  // 不保存
```

### 5. NotesWriter

**实现方案：** URL Scheme

```swift
let urlString = "mobilenotes://action=append&note=\(encodedContent)"
UIApplication.shared.open(URL(string: urlString)!)
```

**笔记模板：**

参见 `LocalizationStrings.noteBodyTemplate()`

```markdown
# 标题

> 摘要

**类别：** 灵感
**标签：** #截图收藏 #灵感
**截取时间：** 2024年9月6日
**保存时间：** 2024年9月6日

---

正文（OCR 识别内容）

---

**结构化信息**
- 日期：...
- 金额：...
- 联系方式：...

**来源：** 用户截图（疑似抖音）
```

### 6. PhotoKitMonitor

**职责：** 后备监控方案

**实现：** `PHPhotoLibraryChangeObserver`

```swift
func photoLibraryDidChange(_ changeInstance: PHChange) {
    // 检测新截图
    checkForNewScreenshots()
}
```

**监控策略：**
1. 仅监听截图类型：`mediaSubtype == .photoScreenshot`
2. 10 秒内的新截图才处理（避免历史误触发）
3. 记录已处理的 `assetId`，防止重复

**通知机制：**
```swift
NotificationCenter.default.post(
    name: NSNotification.Name("NewScreenshotDetected"),
    object: nil,
    userInfo: ["image": image]
)
```

### 7. ProcessScreenshotIntent

**App Intent 定义：**

```swift
@available(iOS 17.0, *)
struct ProcessScreenshotIntent: AppIntent {
    static var title: LocalizedStringResource = "处理最新截图"
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // 获取最新截图
        // 处理并显示筛选框
        return .result()
    }
}
```

**注册到系统：**

```swift
struct ScreenshotToNotesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ProcessScreenshotIntent(),
            phrases: ["处理截图", "截图笔记"],
            shortTitle: "处理截图",
            systemImageName: "doc.text.image"
        )
    }
}
```

## 数据模型

### ExtractedContent

```swift
struct ExtractedContent: Codable, Identifiable {
    let id: UUID
    var title: String
    var summary: String
    var category: NoteCategory          // 分类
    var categoryConfidence: Double      // 置信度
    var tags: [String]                  // 标签
    var body: String                    // 正文
    var entities: EntityInfo            // 实体
    var sourceGuess: SourceGuess        // 来源
    var screenshotTime: Date
    var processedTime: Date
    var imageData: Data?
}
```

### ProcessingRecord

```swift
struct ProcessingRecord: Identifiable, Codable {
    let id: UUID
    let screenshotId: String
    let timestamp: Date
    var status: ProcessingStatus        // pending/success/failed/cancelled
    var content: ExtractedContent?
    var errorMessage: String?
}
```

### AppSettings

```swift
struct AppSettings: Codable {
    var autoSaveEnabled: Bool = true
    var autoSaveTimeout: TimeInterval = 6.0
    var showPreviewBeforeSaving: Bool = false
    var includeImageInNote: Bool = false
    var photoMonitoringEnabled: Bool = true
    var categoryMappings: [NoteCategory: String]
}
```

## 并发安全

### @MainActor 使用

```swift
@MainActor
class CaptureManager: ObservableObject {
    // UI 相关操作必须在主线程
}

@MainActor
class PhotoKitMonitor: ObservableObject {
    // PhotoKit 回调在主线程
}
```

### async/await

```swift
// OCR 异步执行
let ocrResult = try await ocrService.recognizeText(in: image)

// 分类同步（快速）
let classification = classifier.classify(text: ocrResult.fullText)

// Notes 写入异步
try await NotesWriter.shared.writeNote(content: content)
```

## 持久化

### UserDefaults

```swift
// 设置
let data = try? JSONEncoder().encode(settings)
UserDefaults.standard.set(data, forKey: "appSettings")

// 历史记录
let data = try? JSONEncoder().encode(recentRecords)
UserDefaults.standard.set(data, forKey: "recentRecords")

// Onboarding 状态
@AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
@AppStorage("hasEnabledAutomation") var hasEnabledAutomation = false
```

## 权限管理

### 照片权限

```swift
import Photos

let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
    // 处理授权结果
}
```

### 通知权限

```swift
import UserNotifications

UNUserNotificationCenter.current().requestAuthorization(
    options: [.alert, .sound]
) { granted, error in
    // 处理授权结果
}
```

## 测试策略

### 单元测试覆盖

**CategoryClassifierTests:**
- 7 种分类测试
- 4 种来源识别测试
- 置信度计算测试
- 标签提取测试

**ScreenshotToNotesTests:**
- 实体提取测试（日期、金额、联系方式）
- 标题和摘要提取测试

### 手动测试清单

参见 `README_CN.md` § 测试

## 性能优化

1. **OCR 优化**
   - 使用 `.accurate` 级别（平衡速度和准确度）
   - 异步执行，不阻塞 UI

2. **PhotoKit 优化**
   - `fetchLimit = 1`：只获取最新一张
   - 只监听截图类型
   - 10 秒内的新截图才处理

3. **UI 优化**
   - LazyVGrid 延迟加载
   - SwiftUI Preview 支持快速迭代

## 安全和隐私

1. **数据处理**
   - 所有 OCR 在设备本地完成（Vision）
   - 不上传用户截图到服务器
   - 历史记录仅本地存储

2. **权限最小化**
   - 照片：仅读取截图
   - 通知：可选
   - 无网络权限要求

3. **隐私营养标签**
   - 数据类型：照片、诊断数据（可选）
   - 链接到用户：否
   - 用于追踪用户：否

## 已知技术债务

1. **Notes API 限制**
   - 无法指定文件夹
   - 无法更新已有笔记
   - 依赖 URL Scheme，体验不完美

2. **分类器准确度**
   - 启发式规则，非机器学习
   - 需要更多真实数据训练

3. **错误处理**
   - 部分错误信息不够友好
   - 需要更细粒度的错误类型

4. **测试覆盖**
   - UI 测试缺失
   - 集成测试不足

## 未来改进方向

### v1.1

1. **批量处理**
   - 多张截图串行处理
   - 批量确认界面

2. **LLM 分类**
   - 替换启发式分类器
   - 提升准确度

3. **自定义分类**
   - 用户自定义分类规则
   - 导入/导出配置

### v1.2

1. **分享扩展**
   - 从其他 App 分享图片
   - 支持 PDF 等其他格式

2. **Widget**
   - 显示最近保存的笔记
   - 快速入口

3. **macOS 版本**
   - Mac Catalyst 或原生 AppKit
   - Drag & Drop 支持

## 参考资料

- [Vision Framework 文档](https://developer.apple.com/documentation/vision)
- [App Intents 文档](https://developer.apple.com/documentation/appintents)
- [PhotoKit 文档](https://developer.apple.com/documentation/photokit)
- [SwiftUI 文档](https://developer.apple.com/documentation/swiftui)

---

**文档版本：** v1.0  
**最后更新：** 2024-09-06
