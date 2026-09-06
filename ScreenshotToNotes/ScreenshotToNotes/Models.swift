import Foundation
import SwiftUI

// MARK: - 类别定义
enum NoteCategory: String, CaseIterable, Codable {
    case insight = "灵感"
    case howto = "方法"
    case task = "待办"
    case receipt = "单据"
    case contact = "联系人"
    case product = "收藏"
    case inbox = "收件箱"
    case other = "其他"
    
    var folderName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .insight: return "lightbulb.fill"
        case .howto: return "list.bullet.clipboard"
        case .task: return "checkmark.circle.fill"
        case .receipt: return "doc.text.fill"
        case .contact: return "person.fill"
        case .product: return "star.fill"
        case .inbox: return "tray.fill"
        case .other: return "folder.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .insight: return .yellow
        case .howto: return .blue
        case .task: return .green
        case .receipt: return .orange
        case .contact: return .purple
        case .product: return .pink
        case .inbox: return .gray
        case .other: return .gray
        }
    }
}

// MARK: - 来源类型
enum SourceGuess: String, Codable {
    case douyin = "抖音"
    case twitter = "Twitter/X"
    case wechat = "微信公众号"
    case xiaohongshu = "小红书"
    case chat = "聊天"
    case web = "网页"
    case unknown = "未知"
}

// MARK: - 提取结果
struct ExtractedContent: Codable, Identifiable {
    let id: UUID
    var title: String
    var summary: String
    var category: NoteCategory
    var categoryConfidence: Double
    var tags: [String]
    var body: String
    var entities: EntityInfo
    var sourceGuess: SourceGuess
    var screenshotTime: Date
    var processedTime: Date
    var imageData: Data?
    
    struct EntityInfo: Codable {
        var dates: [String]
        var amounts: [String]
        var ids: [String]
        var contacts: [String]
        var links: [String]
    }
    
    init(
        id: UUID = UUID(),
        title: String = "",
        summary: String = "",
        category: NoteCategory = .inbox,
        categoryConfidence: Double = 0.0,
        tags: [String] = [],
        body: String = "",
        entities: EntityInfo = EntityInfo(dates: [], amounts: [], ids: [], contacts: [], links: []),
        sourceGuess: SourceGuess = .unknown,
        screenshotTime: Date = Date(),
        processedTime: Date = Date(),
        imageData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.category = category
        self.categoryConfidence = categoryConfidence
        self.tags = tags
        self.body = body
        self.entities = entities
        self.sourceGuess = sourceGuess
        self.screenshotTime = screenshotTime
        self.processedTime = processedTime
        self.imageData = imageData
    }
}

// MARK: - 处理记录
struct ProcessingRecord: Identifiable, Codable {
    let id: UUID
    let screenshotId: String
    let timestamp: Date
    var status: ProcessingStatus
    var content: ExtractedContent?
    var errorMessage: String?
    
    enum ProcessingStatus: String, Codable {
        case pending = "处理中"
        case success = "成功"
        case failed = "失败"
        case cancelled = "已取消"
    }
    
    init(
        id: UUID = UUID(),
        screenshotId: String,
        timestamp: Date = Date(),
        status: ProcessingStatus = .pending,
        content: ExtractedContent? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.screenshotId = screenshotId
        self.timestamp = timestamp
        self.status = status
        self.content = content
        self.errorMessage = errorMessage
    }
}

// MARK: - App 设置
struct AppSettings: Codable {
    var autoSaveEnabled: Bool = true
    var autoSaveTimeout: TimeInterval = 6.0
    var showPreviewBeforeSaving: Bool = false
    var includeImageInNote: Bool = false
    var photoMonitoringEnabled: Bool = true
    var categoryMappings: [NoteCategory: String] = [:]
    
    init() {
        for category in NoteCategory.allCases {
            categoryMappings[category] = category.folderName
        }
    }
}
