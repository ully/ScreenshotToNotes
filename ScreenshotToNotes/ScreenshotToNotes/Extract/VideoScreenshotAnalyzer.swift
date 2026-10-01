import Foundation
import UIKit

class VideoScreenshotAnalyzer {
    func analyzeVideoScreenshot(text: String, sourceGuess: SourceGuess) -> VideoAnalysisResult {
        guard sourceGuess.isVideoApp else {
            return VideoAnalysisResult(isVideo: false)
        }
        
        let author = extractAuthor(from: text, source: sourceGuess)
        let duration = extractDuration(from: text)
        let stats = extractVideoStats(from: text, source: sourceGuess)
        let videoType = detectVideoType(from: text)
        let topics = extractVideoTopics(from: text)
        
        return VideoAnalysisResult(
            isVideo: true,
            author: author,
            duration: duration,
            stats: stats,
            videoType: videoType,
            topics: topics
        )
    }
    
    private func extractAuthor(from text: String, source: SourceGuess) -> String? {
        let patterns: [String]
        
        switch source {
        case .douyin:
            patterns = ["@([\\w\\u4e00-\\u9fa5]+)", "作者[：:]([\

\\u4e00-\\u9fa5]+)"]
        case .kuaishou:
            patterns = ["@([\\w\\u4e00-\\u9fa5]+)", "快手号[：:]([\\w]+)"]
        case .bilibili:
            patterns = ["@([\\w\\u4e00-\\u9fa5]+)", "UP主[：:]([\

\\u4e00-\\u9fa5]+)"]
        case .xiaohongshu:
            patterns = ["@([\\w\\u4e00-\\u9fa5]+)", "小红书号[：:]([\\w]+)"]
        default:
            patterns = ["@([\\w\\u4e00-\\u9fa5]+)"]
        }
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }
        
        return nil
    }
    
    private func extractDuration(from text: String) -> String? {
        let durationPattern = "(\\d{1,2}):(\\d{2})"
        
        guard let regex = try? NSRegularExpression(pattern: durationPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else {
            return nil
        }
        
        return String(text[range])
    }
    
    private func extractVideoStats(from text: String, source: SourceGuess) -> ExtractedContent.VideoStats {
        var stats = ExtractedContent.VideoStats()
        
        let patterns: [(key: String, patterns: [String])] = [
            ("likes", ["(\\d+\\.?\\d*[万wkK]?)\\s*赞", "点赞\\s*(\\d+\\.?\\d*[万wkK]?)", "(\\d+\\.?\\d*[万wkK]?)\\s*👍"]),
            ("comments", ["(\\d+\\.?\\d*[万wkK]?)\\s*评论", "评论\\s*(\\d+\\.?\\d*[万wkK]?)", "(\\d+\\.?\\d*[万wkK]?)\\s*💬"]),
            ("shares", ["(\\d+\\.?\\d*[万wkK]?)\\s*转发", "分享\\s*(\\d+\\.?\\d*[万wkK]?)", "(\\d+\\.?\\d*[万wkK]?)\\s*🔗"]),
            ("views", ["(\\d+\\.?\\d*[万wkK]?)\\s*播放", "观看\\s*(\\d+\\.?\\d*[万wkK]?)", "(\\d+\\.?\\d*[万wkK]?)次"])
        ]
        
        for (key, patternList) in patterns {
            for pattern in patternList {
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                   match.numberOfRanges > 1,
                   let range = Range(match.range(at: 1), in: text) {
                    let value = String(text[range])
                    switch key {
                    case "likes": stats.likes = value
                    case "comments": stats.comments = value
                    case "shares": stats.shares = value
                    case "views": stats.views = value
                    default: break
                    }
                    break
                }
            }
        }
        
        return stats
    }
    
    private func detectVideoType(from text: String) -> VideoType {
        let typeIndicators: [(VideoType, [String])] = [
            (.tutorial, ["教程", "教学", "学习", "课程", "怎么做", "如何", "步骤", "攻略", "指南"]),
            (.food, ["美食", "做菜", "食谱", "烹饪", "料理", "厨房", "菜谱", "好吃"]),
            (.fitness, ["健身", "运动", "锻炼", "瑜伽", "减肥", "训练", "跑步", "增肌"]),
            (.entertainment, ["搞笑", "娱乐", "段子", "有趣", "笑话", "综艺", "表演"]),
            (.travel, ["旅游", "旅行", "景点", "游记", "风景", "探店", "打卡"]),
            (.tech, ["科技", "数码", "手机", "电脑", "软件", "app", "测评", "评测"]),
            (.beauty, ["美妆", "化妆", "护肤", "彩妆", "口红", "粉底", "面膜"]),
            (.vlog, ["vlog", "日常", "记录", "生活", "一天", "日记"]),
            (.music, ["音乐", "歌曲", "唱歌", "翻唱", "mv", "演唱"]),
            (.dance, ["舞蹈", "跳舞", "编舞", "dance"])
        ]
        
        let lowercasedText = text.lowercased()
        
        for (type, keywords) in typeIndicators {
            for keyword in keywords {
                if lowercasedText.contains(keyword) {
                    return type
                }
            }
        }
        
        return .other
    }
    
    private func extractVideoTopics(from text: String) -> [String] {
        var topics: [String] = []
        
        let hashtagPattern = "#([\\w\\u4e00-\\u9fa5]+)"
        if let regex = try? NSRegularExpression(pattern: hashtagPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if match.numberOfRanges > 1,
                   let range = Range(match.range(at: 1), in: text) {
                    topics.append(String(text[range]))
                }
            }
        }
        
        return topics
    }
}

struct VideoAnalysisResult {
    let isVideo: Bool
    var author: String? = nil
    var duration: String? = nil
    var stats: ExtractedContent.VideoStats? = nil
    var videoType: VideoType = .other
    var topics: [String] = []
}

enum VideoType: String {
    case tutorial = "教程"
    case food = "美食"
    case fitness = "健身"
    case entertainment = "娱乐"
    case travel = "旅行"
    case tech = "科技数码"
    case beauty = "美妆"
    case vlog = "Vlog"
    case music = "音乐"
    case dance = "舞蹈"
    case other = "其他"
    
    var suggestedCategory: NoteCategory {
        switch self {
        case .tutorial:
            return .videoTutorial
        case .entertainment, .music, .dance, .vlog:
            return .videoEntertainment
        default:
            return .videoCollection
        }
    }
}
