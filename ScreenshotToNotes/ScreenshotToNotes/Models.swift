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
    case videoCollection = "视频收藏"
    case videoTutorial = "教程视频"
    case videoEntertainment = "娱乐视频"
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
        case .videoCollection: return "play.rectangle.fill"
        case .videoTutorial: return "graduationcap.fill"
        case .videoEntertainment: return "sparkles.tv.fill"
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
        case .videoCollection: return .red
        case .videoTutorial: return .cyan
        case .videoEntertainment: return .indigo
        case .inbox: return .gray
        case .other: return .gray
        }
    }
}

// MARK: - 来源类型
enum SourceGuess: String, Codable {
    // 国内视频平台
    case douyin = "抖音"
    case kuaishou = "快手"
    case bilibili = "哔哩哔哩"
    case xiaohongshu = "小红书"
    case xigua = "西瓜视频"
    
    // 国际视频平台
    case youtube = "YouTube"
    case tiktok = "TikTok"
    case instagram = "Instagram"
    case facebook = "Facebook"
    case twitch = "Twitch"
    case vimeo = "Vimeo"
    case reddit = "Reddit"
    
    // 其他
    case twitter = "Twitter/X"
    case wechat = "微信公众号"
    case chat = "聊天"
    case web = "网页"
    case unknown = "未知"
    
    var isVideoApp: Bool {
        switch self {
        case .douyin, .kuaishou, .bilibili, .xiaohongshu, .xigua,
             .youtube, .tiktok, .instagram, .facebook, .twitch, .vimeo, .reddit:
            return true
        default:
            return false
        }
    }
    
    var region: VideoRegion {
        switch self {
        case .douyin, .kuaishou, .bilibili, .xiaohongshu, .xigua:
            return .china
        case .youtube, .tiktok, .instagram, .facebook, .twitch, .vimeo, .reddit:
            return .international
        default:
            return .other
        }
    }
}

enum VideoRegion {
    case china
    case international
    case other
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
        var videoAuthor: String?
        var videoDuration: String?
        var videoStats: VideoStats?
    }
    
    struct VideoStats: Codable {
        var likes: String?
        var comments: String?
        var shares: String?
        var views: String?
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
