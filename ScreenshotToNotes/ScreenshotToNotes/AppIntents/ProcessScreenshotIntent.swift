import Foundation
import AppIntents
import UIKit

@available(iOS 17.0, *)
struct ProcessScreenshotIntent: AppIntent {
    static var title: LocalizedStringResource = "处理最新截图"
    static var description = IntentDescription("获取最新截图并进行文字提取和分类")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        print("🎯 ProcessScreenshotIntent 被调用")
        
        let captureManager = CaptureManager.shared
        
        guard let image = await captureManager.getLatestScreenshot() else {
            print("❌ 未找到最新截图")
            throw ProcessScreenshotError.noScreenshotFound
        }
        
        print("✅ 找到最新截图，开始处理")
        
        do {
            let content = try await captureManager.processScreenshot(image)
            
            print("✅ 处理完成: \(content.title)")
            
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowFilterSheet"),
                object: nil,
                userInfo: ["content": content]
            )
            
            return .result()
        } catch {
            print("❌ 处理失败: \(error.localizedDescription)")
            throw error
        }
    }
}

@available(iOS 17.0, *)
enum ProcessScreenshotError: Error, LocalizedError {
    case noScreenshotFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .noScreenshotFound:
            return "未找到最新截图"
        case .processingFailed:
            return "处理截图失败"
        }
    }
}

@available(iOS 17.0, *)
struct ScreenshotToNotesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ProcessScreenshotIntent(),
            phrases: [
                "处理截图",
                "截图笔记",
                "保存截图到备忘录"
            ],
            shortTitle: "处理截图",
            systemImageName: "doc.text.image"
        )
    }
}
